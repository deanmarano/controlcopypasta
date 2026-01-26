defmodule Controlcopypasta.Nutrition.OpenFoodFactsClient do
  @moduledoc """
  Client for Open Food Facts API.

  Open Food Facts is a free, open, collaborative database of food products
  from around the world. It's particularly good for branded products.

  ## API Documentation
  https://wiki.openfoodfacts.org/API

  No API key required. Please be respectful of rate limits.
  """

  require Logger

  @base_url "https://world.openfoodfacts.org"
  @user_agent "ControlCopyPasta/1.0 (recipe management app)"

  @doc """
  Search for products by name.

  Returns a list of matching products with nutrition data.

  ## Options
  - `:page_size` - Number of results (default 10, max 100)
  - `:page` - Page number (default 1)

  ## Examples

      iex> search("coca cola")
      {:ok, [%{code: "5449000000996", product_name: "Coca-Cola", ...}, ...]}
  """
  def search(query, opts \\ []) do
    page_size = opts[:page_size] || 10
    page = opts[:page] || 1

    params = %{
      search_terms: query,
      search_simple: 1,
      action: "process",
      json: 1,
      page_size: page_size,
      page: page,
      # Only get products with nutrition data
      tagtype_0: "states",
      tag_contains_0: "contains",
      tag_0: "en:nutrition-facts-completed"
    }

    url = "#{@base_url}/cgi/search.pl?#{URI.encode_query(params)}"

    case http_get(url) do
      {:ok, %{"products" => products}} ->
        results = Enum.map(products, &parse_product/1)
        {:ok, results}

      {:ok, _} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get a specific product by barcode.
  """
  def get_product(barcode) do
    url = "#{@base_url}/api/v0/product/#{barcode}.json"

    case http_get(url) do
      {:ok, %{"status" => 1, "product" => product}} ->
        {:ok, parse_product(product)}

      {:ok, %{"status" => 0}} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Search and get the best matching product's nutrition data.
  """
  def search_and_get_nutrition(query, opts \\ []) do
    case search(query, opts) do
      {:ok, []} ->
        {:error, :not_found}

      {:ok, products} ->
        # Find best match with complete nutrition data
        case Enum.find(products, &has_nutrition?/1) do
          nil -> {:error, :no_nutrition_data}
          product -> {:ok, product}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse product into a standardized structure
  defp parse_product(product) do
    nutriments = product["nutriments"] || %{}

    %{
      code: product["code"],
      product_name: product["product_name"] || product["product_name_en"],
      brand: product["brands"],
      categories: product["categories"],
      serving_size: product["serving_size"],
      serving_quantity: product["serving_quantity"],
      image_url: product["image_url"],
      # Nutrition per 100g
      nutrients: %{
        calories: get_nutrient(nutriments, "energy-kcal_100g"),
        protein_g: get_nutrient(nutriments, "proteins_100g"),
        fat_total_g: get_nutrient(nutriments, "fat_100g"),
        fat_saturated_g: get_nutrient(nutriments, "saturated-fat_100g"),
        fat_trans_g: get_nutrient(nutriments, "trans-fat_100g"),
        carbohydrates_g: get_nutrient(nutriments, "carbohydrates_100g"),
        fiber_g: get_nutrient(nutriments, "fiber_100g"),
        sugar_g: get_nutrient(nutriments, "sugars_100g"),
        sodium_mg: calculate_sodium(nutriments),
        potassium_mg: get_nutrient(nutriments, "potassium_100g"),
        calcium_mg: get_nutrient(nutriments, "calcium_100g"),
        iron_mg: get_nutrient(nutriments, "iron_100g"),
        vitamin_a_mcg: get_nutrient(nutriments, "vitamin-a_100g"),
        vitamin_c_mg: get_nutrient(nutriments, "vitamin-c_100g"),
        vitamin_d_mcg: get_nutrient(nutriments, "vitamin-d_100g"),
        cholesterol_mg: get_nutrient(nutriments, "cholesterol_100g")
      }
    }
  end

  defp get_nutrient(nutriments, key) do
    case nutriments[key] do
      nil -> nil
      "" -> nil
      val when is_number(val) -> val
      val when is_binary(val) ->
        case Float.parse(val) do
          {num, _} -> num
          :error -> nil
        end
    end
  end

  # Open Food Facts stores salt, we need to convert to sodium
  # Sodium (mg) = Salt (g) * 400
  defp calculate_sodium(nutriments) do
    case get_nutrient(nutriments, "sodium_100g") do
      nil ->
        case get_nutrient(nutriments, "salt_100g") do
          nil -> nil
          salt_g -> salt_g * 400
        end
      sodium -> sodium * 1000  # Convert g to mg if in grams
    end
  end

  defp has_nutrition?(product) do
    nutrients = product.nutrients
    # Must have at least calories and one macro
    nutrients.calories != nil and
      (nutrients.protein_g != nil or nutrients.carbohydrates_g != nil or nutrients.fat_total_g != nil)
  end

  defp http_get(url) do
    case Req.get(url, headers: [{"user-agent", @user_agent}], receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: 429}} ->
        Logger.warning("Open Food Facts rate limit hit")
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Open Food Facts API error: #{status} - #{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("Open Food Facts API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
