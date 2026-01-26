defmodule Controlcopypasta.Nutrition.SpoonacularClient do
  @moduledoc """
  Client for Spoonacular API - used for ingredient images.

  Spoonacular has a database of 2600+ ingredients with high-quality images.

  ## Setup

  1. Get a free API key at: https://spoonacular.com/food-api
  2. Add to your environment: `export SPOONACULAR_API_KEY=your_key_here`

  ## API Limits (Free tier)

  - 150 requests/day
  - 1 request/second

  ## Image URL Format

  Images are served from: https://img.spoonacular.com/ingredients_{SIZE}/{IMAGE_NAME}
  Sizes: 100x100, 250x250, 500x500
  """

  require Logger

  @base_url "https://api.spoonacular.com"
  @image_base_url "https://img.spoonacular.com/ingredients"

  @doc """
  Search for ingredients by name.

  Returns a list of matching ingredients with their image names.

  ## Options
  - `:number` - Number of results (default 5, max 100)

  ## Examples

      iex> search("tomato")
      {:ok, [%{id: 11529, name: "tomato", image: "tomato.png"}, ...]}
  """
  def search(query, opts \\ []) do
    api_key = get_api_key()

    unless api_key do
      {:error, :api_key_missing}
    else
      number = opts[:number] || 5

      params = %{
        apiKey: api_key,
        query: query,
        number: number,
        metaInformation: true
      }

      url = "#{@base_url}/food/ingredients/search?#{URI.encode_query(params)}"

      case http_get(url) do
        {:ok, %{"results" => results}} ->
          ingredients = Enum.map(results, fn r ->
            %{
              id: r["id"],
              name: r["name"],
              image: r["image"]
            }
          end)
          {:ok, ingredients}

        {:ok, _} ->
          {:ok, []}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Get ingredient information by ID.

  Returns detailed info including the image filename.
  """
  def get_ingredient(id, opts \\ []) do
    api_key = get_api_key()

    unless api_key do
      {:error, :api_key_missing}
    else
      amount = opts[:amount] || 1
      unit = opts[:unit] || ""

      params = %{
        apiKey: api_key,
        amount: amount,
        unit: unit
      }

      url = "#{@base_url}/food/ingredients/#{id}/information?#{URI.encode_query(params)}"

      case http_get(url) do
        {:ok, info} ->
          {:ok, %{
            id: info["id"],
            name: info["name"],
            image: info["image"],
            category: info["categoryPath"] |> List.first(),
            image_url: build_image_url(info["image"], "250x250")
          }}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Builds a full image URL for an ingredient.

  ## Sizes
  - "100x100" - Thumbnail
  - "250x250" - Medium
  - "500x500" - Large

  ## Examples

      iex> build_image_url("tomato.png", "250x250")
      "https://img.spoonacular.com/ingredients_250x250/tomato.png"
  """
  def build_image_url(nil, _size), do: nil
  def build_image_url(image_name, size) when size in ["100x100", "250x250", "500x500"] do
    "#{@image_base_url}_#{size}/#{image_name}"
  end
  def build_image_url(image_name, _size), do: build_image_url(image_name, "250x250")

  @doc """
  Search and get the best matching ingredient's image URL.

  Convenience function that searches and returns the top match's image.
  """
  def get_ingredient_image(query, opts \\ []) do
    size = opts[:size] || "250x250"

    case search(query, number: 1) do
      {:ok, []} ->
        {:error, :not_found}

      {:ok, [best | _]} ->
        {:ok, build_image_url(best.image, size)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # HTTP helpers
  defp http_get(url) do
    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        log_quota(headers)
        {:ok, body}

      {:ok, %{status: 401}} ->
        Logger.error("Spoonacular API: Invalid API key")
        {:error, :invalid_api_key}

      {:ok, %{status: 402, headers: headers}} ->
        log_quota(headers)
        Logger.warning("Spoonacular API: Daily limit exceeded")
        {:error, :daily_limit_exceeded}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Spoonacular API error: #{status} - #{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("Spoonacular API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp log_quota(headers) do
    # Headers come as a list of {name, value} tuples or a map
    get_header = fn name ->
      case headers do
        %{} -> Map.get(headers, name) || Map.get(headers, String.downcase(name))
        list when is_list(list) ->
          Enum.find_value(list, fn
            {^name, v} -> v
            {n, v} when is_binary(n) -> if String.downcase(n) == String.downcase(name), do: v
            _ -> nil
          end)
      end
    end

    used = get_header.("x-api-quota-used")
    left = get_header.("x-api-quota-left")
    request = get_header.("x-api-quota-request")

    if used || left do
      Logger.info("Spoonacular quota: #{used} used, #{left} left (this request: #{request} points)")
    end
  end

  defp get_api_key do
    System.get_env("SPOONACULAR_API_KEY") ||
      Application.get_env(:controlcopypasta, :spoonacular_api_key)
  end

  @doc """
  Checks if API key is configured.
  """
  def api_key_configured? do
    get_api_key() != nil
  end
end
