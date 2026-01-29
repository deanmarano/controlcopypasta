defmodule Controlcopypasta.Nutrition.OpenFoodFactsClient do
  @moduledoc """
  Client for Open Food Facts API.

  Open Food Facts is a free, open, collaborative database of food products
  from around the world. Good for branded products and international items.

  ## API Documentation
  https://openfoodfacts.github.io/openfoodfacts-server/api/

  ## Rate Limits
  - Search queries: 10 req/min (GET /cgi/search.pl)
  - Product queries: 100 req/min (GET /api/v2/product)
  - Facet queries: 2 req/min (not used in this client)

  We use the US database (us.openfoodfacts.org) for better serving size data
  since US products often include volume measurements (tbsp, cup).
  """

  require Logger

  # Use US database for better serving size data (tbsp, cups)
  @api_base "https://us.openfoodfacts.org"
  @world_api_base "https://world.openfoodfacts.org"

  # User-Agent required by Open Food Facts
  @user_agent "ControlCopyPasta/1.0 (https://controlcopypasta.com; contact@controlcopypasta.com)"

  @doc """
  Search for products by name.

  Uses the US database first (better serving sizes), falls back to world database.

  ## Options
  - `:page` - Page number (default 1)
  - `:page_size` - Results per page (default 10, max 100)

  ## Rate Limit
  10 requests per minute. Caller should respect this.

  ## Examples

      iex> search("olive oil")
      {:ok, [%{code: "123", product_name: "Extra Virgin Olive Oil", ...}, ...]}
  """
  def search(query, opts \\ []) do
    page = opts[:page] || 1
    page_size = opts[:page_size] || 10

    # Fields we need for density extraction
    fields = "code,product_name,brands,serving_size,serving_quantity,product_quantity,nutriments"

    params = %{
      search_terms: query,
      search_simple: 1,
      action: "process",
      json: 1,
      page: page,
      page_size: page_size,
      fields: fields
    }

    # Try US database first (better serving sizes)
    case do_search(@api_base, params) do
      {:ok, []} ->
        # Fall back to world database
        do_search(@world_api_base, params)

      result ->
        result
    end
  end

  defp do_search(base_url, params) do
    url = "#{base_url}/cgi/search.pl"
    query = URI.encode_query(params)
    full_url = "#{url}?#{query}"

    headers = [{"user-agent", @user_agent}]

    case Req.get(full_url, headers: headers, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: %{"products" => products}}} when is_list(products) ->
        {:ok, Enum.map(products, &parse_search_result/1)}

      {:ok, %{status: 200, body: _}} ->
        {:ok, []}

      {:ok, %{status: 429}} ->
        Logger.warning("Open Food Facts API rate limit hit")
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Open Food Facts API error: #{status} - #{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("Open Food Facts request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_search_result(product) do
    %{
      code: product["code"],
      product_name: product["product_name"],
      brands: product["brands"],
      serving_size: product["serving_size"],
      serving_quantity: product["serving_quantity"],
      product_quantity: product["product_quantity"]
    }
  end

  @doc """
  Get detailed product data by barcode.

  ## Rate Limit
  100 requests per minute.

  ## Examples

      iex> get_product("3017620422003")
      {:ok, %{code: "3017620422003", product_name: "Nutella", ...}}
  """
  def get_product(code, opts \\ []) do
    # Try US first, then world
    base = if opts[:world], do: @world_api_base, else: @api_base

    url = "#{base}/api/v2/product/#{code}.json"
    headers = [{"user-agent", @user_agent}]

    case Req.get(url, headers: headers, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: %{"status" => 1, "product" => product}}} ->
        {:ok, parse_product_detail(product)}

      {:ok, %{status: 200, body: %{"status" => 0}}} ->
        # Product not found, try world database if we were on US
        if base == @api_base do
          get_product(code, world: true)
        else
          {:error, :not_found}
        end

      {:ok, %{status: 429}} ->
        Logger.warning("Open Food Facts API rate limit hit")
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Open Food Facts API error: #{status} - #{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("Open Food Facts request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_product_detail(product) do
    %{
      code: product["code"],
      product_name: product["product_name"],
      brands: product["brands"],
      serving_size: product["serving_size"],
      serving_quantity: product["serving_quantity"],
      product_quantity: product["product_quantity"],
      categories: product["categories"],
      nutriments: product["nutriments"],
      raw: product
    }
  end

  @doc """
  Fetches a product and returns both parsed data and raw response for density extraction.
  """
  def get_product_with_raw(code, opts \\ []) do
    case get_product(code, opts) do
      {:ok, %{raw: raw} = parsed} ->
        {:ok, %{parsed: Map.delete(parsed, :raw), raw: raw}}

      error ->
        error
    end
  end

  @doc """
  Search and get the first matching product with raw data.
  Returns {:ok, %{parsed: ..., raw: ...}} or {:error, reason}
  """
  def search_and_get_first(query, opts \\ []) do
    case search(query, Keyword.merge(opts, page_size: 5)) do
      {:ok, [first | _]} ->
        get_product_with_raw(first.code)

      {:ok, []} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Extracts density data from raw Open Food Facts API response.

  Parses serving_size strings like:
  - "1 tbsp (14 g)"
  - "1 Tbsp (15 ml)"
  - "0.5 cup (85 g)"
  - "15 g"

  Returns a list of density maps suitable for IngredientDensity.
  """
  def extract_densities_from_raw(raw_product, canonical_ingredient_id) do
    code = raw_product["code"]
    product_url = "https://world.openfoodfacts.org/product/#{code}"
    serving_size = raw_product["serving_size"]

    if serving_size do
      case parse_serving_size(serving_size) do
        {:ok, volume_unit, grams} when grams > 0 ->
          [%{
            canonical_ingredient_id: canonical_ingredient_id,
            volume_unit: volume_unit,
            grams_per_unit: grams,
            preparation: nil,
            source: "openfoodfacts",
            source_id: code,
            source_url: product_url,
            confidence: Decimal.new("0.70"),  # Slightly lower confidence than FatSecret
            retrieved_at: DateTime.utc_now(),
            notes: serving_size
          }]

        _ ->
          []
      end
    else
      []
    end
  end

  @doc """
  Parses a serving_size string to extract volume unit and grams.

  ## Examples

      iex> parse_serving_size("1 tbsp (14 g)")
      {:ok, "tbsp", 14.0}

      iex> parse_serving_size("0.5 cup (85 g)")
      {:ok, "cup", 170.0}  # Normalized to 1 cup

      iex> parse_serving_size("15 g")
      :error  # No volume unit
  """
  def parse_serving_size(serving_size) when is_binary(serving_size) do
    serving = String.downcase(serving_size)

    # Try to match patterns like "1 tbsp (14 g)" or "1/2 cup (60g)"
    with {:ok, volume_qty, volume_unit} <- extract_volume(serving),
         {:ok, grams} <- extract_grams(serving) do
      # Normalize to per-unit (e.g., if "0.5 cup (85 g)", calculate for 1 cup)
      grams_per_unit = if volume_qty > 0, do: grams / volume_qty, else: grams
      {:ok, volume_unit, grams_per_unit}
    else
      _ -> :error
    end
  end

  def parse_serving_size(_), do: :error

  # Extract volume quantity and unit from serving string
  defp extract_volume(serving) do
    # Match volume units - includes common typos/variations found in Open Food Facts
    # thsp = common typo for tbsp
    # T/t = abbreviation for tablespoon
    volume_units = "cups?|tbsps?|thsps?|tablespoons?|tsps?|teaspoons?|fl\\s*oz"

    patterns = [
      # "1 tbsp", "1/2 cup", "0.5 cup", "2 thsp"
      {~r/(\d+(?:[.,\/]\d+)?)\s*(#{volume_units})\b/, fn qty, unit ->
        {parse_quantity(qty), normalize_volume_unit(unit)}
      end},
      # "one tablespoon"
      {~r/\b(one|two|three|four)\s*(#{volume_units})\b/, fn word, unit ->
        {word_to_number(word), normalize_volume_unit(unit)}
      end}
    ]

    Enum.find_value(patterns, :error, fn {regex, parser} ->
      case Regex.run(regex, serving) do
        [_, qty, unit] ->
          {volume_qty, volume_unit} = parser.(qty, unit)
          if volume_qty && volume_unit, do: {:ok, volume_qty, volume_unit}

        _ ->
          nil
      end
    end)
  end

  # Extract grams from serving string
  defp extract_grams(serving) do
    patterns = [
      # "(14 g)", "(14g)", "(14 grams)"
      ~r/\((\d+(?:[.,]\d+)?)\s*(?:g|grams?)\)/,
      # "14 g" at end
      ~r/(\d+(?:[.,]\d+)?)\s*(?:g|grams?)\s*$/
    ]

    Enum.find_value(patterns, :error, fn regex ->
      case Regex.run(regex, serving) do
        [_, grams_str] ->
          case parse_quantity(grams_str) do
            nil -> nil
            grams -> {:ok, grams}
          end

        _ ->
          nil
      end
    end)
  end

  defp normalize_volume_unit(unit) do
    case String.downcase(unit) do
      u when u in ~w(cup cups) -> "cup"
      # thsp is a common typo in Open Food Facts data
      u when u in ~w(tbsp tbsps thsp thsps tablespoon tablespoons) -> "tbsp"
      u when u in ~w(tsp tsps teaspoon teaspoons) -> "tsp"
      "fl oz" -> "fl oz"
      _ -> nil
    end
  end

  defp parse_quantity(str) do
    str = String.trim(str)

    cond do
      # Fraction like "1/2"
      String.contains?(str, "/") ->
        case String.split(str, "/") do
          [num, den] ->
            with {n, _} <- Float.parse(num),
                 {d, _} <- Float.parse(den),
                 true <- d != 0 do
              n / d
            else
              _ -> nil
            end

          _ ->
            nil
        end

      # Decimal or integer
      true ->
        case Float.parse(String.replace(str, ",", ".")) do
          {val, _} -> val
          :error -> nil
        end
    end
  end

  defp word_to_number("one"), do: 1.0
  defp word_to_number("two"), do: 2.0
  defp word_to_number("three"), do: 3.0
  defp word_to_number("four"), do: 4.0
  defp word_to_number(_), do: nil
end
