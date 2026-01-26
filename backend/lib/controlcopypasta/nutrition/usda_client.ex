defmodule Controlcopypasta.Nutrition.USDAClient do
  @moduledoc """
  Client for USDA FoodData Central API.

  The USDA FoodData Central API provides comprehensive nutrition data for foods.
  It's free to use and is considered the gold standard for nutrition data in the US.

  ## Setup

  1. Get a free API key at: https://fdc.nal.usda.gov/api-key-signup.html
  2. Add to your environment: `export USDA_API_KEY=your_key_here`
  3. Or add to config: `config :controlcopypasta, :usda_api_key, "your_key_here"`

  ## API Documentation
  https://fdc.nal.usda.gov/api-guide.html

  ## Data Types
  - Foundation Foods: Standardized reference data (most accurate)
  - SR Legacy: USDA Standard Reference (comprehensive)
  - Survey (FNDDS): What Americans Eat data
  - Branded: Commercial products from labels

  We prioritize Foundation and SR Legacy for canonical ingredients.
  """

  require Logger

  @base_url "https://api.nal.usda.gov/fdc/v1"

  # Nutrient IDs from USDA FoodData Central
  @nutrient_ids %{
    # Proximates
    calories: 1008,        # Energy (kcal)
    protein_g: 1003,       # Protein
    fat_total_g: 1004,     # Total lipid (fat)
    carbohydrates_g: 1005, # Carbohydrate, by difference
    fiber_g: 1079,         # Fiber, total dietary
    sugar_g: 2000,         # Sugars, total
    sugar_added_g: 1235,   # Sugars, added
    water_g: 1051,         # Water

    # Lipids
    fat_saturated_g: 1258,       # Fatty acids, total saturated
    fat_trans_g: 1257,           # Fatty acids, total trans
    fat_monounsaturated_g: 1292, # Fatty acids, total monounsaturated
    fat_polyunsaturated_g: 1293, # Fatty acids, total polyunsaturated
    cholesterol_mg: 1253,        # Cholesterol

    # Minerals
    sodium_mg: 1093,     # Sodium
    potassium_mg: 1092,  # Potassium
    calcium_mg: 1087,    # Calcium
    iron_mg: 1089,       # Iron
    magnesium_mg: 1090,  # Magnesium
    phosphorus_mg: 1091, # Phosphorus
    zinc_mg: 1095,       # Zinc

    # Vitamins
    vitamin_a_mcg: 1106,   # Vitamin A, RAE
    vitamin_c_mg: 1162,    # Vitamin C
    vitamin_d_mcg: 1114,   # Vitamin D (D2 + D3)
    vitamin_e_mg: 1109,    # Vitamin E (alpha-tocopherol)
    vitamin_k_mcg: 1185,   # Vitamin K (phylloquinone)
    vitamin_b6_mg: 1175,   # Vitamin B-6
    vitamin_b12_mcg: 1178, # Vitamin B-12
    folate_mcg: 1177,      # Folate, total
    thiamin_mg: 1165,      # Thiamin (B1)
    riboflavin_mg: 1166,   # Riboflavin (B2)
    niacin_mg: 1167        # Niacin (B3)
  }

  @doc """
  Search for foods by name.

  Returns a list of matching foods with basic info.
  Use `get_food/1` to get full nutrition data.

  ## Options
  - `:data_type` - Filter by data type: "Foundation", "SR Legacy", "Survey (FNDDS)", "Branded"
  - `:page_size` - Number of results (default 25, max 200)
  - `:api_key` - Optional API key for higher rate limits

  ## Examples

      iex> search("chicken breast")
      {:ok, [%{fdc_id: 171077, description: "Chicken, breast, meat only, cooked, roasted", ...}, ...]}
  """
  def search(query, opts \\ []) do
    api_key = opts[:api_key] || get_api_key()
    page_size = opts[:page_size] || 25

    # Prefer Foundation and SR Legacy for accuracy
    data_types = opts[:data_type] || ["Foundation", "SR Legacy"]

    body = %{
      query: query,
      dataType: List.wrap(data_types),
      pageSize: page_size,
      sortBy: "dataType.keyword",
      sortOrder: "asc"
    }

    url = "#{@base_url}/foods/search"
    url = if api_key, do: "#{url}?api_key=#{api_key}", else: url

    case http_post(url, body) do
      {:ok, %{"foods" => foods}} ->
        results = Enum.map(foods, &parse_search_result/1)
        {:ok, results}

      {:ok, response} ->
        Logger.warning("Unexpected USDA search response: #{inspect(response)}")
        {:error, :unexpected_response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get detailed nutrition data for a specific food by FDC ID.

  ## Examples

      iex> get_food(171077)
      {:ok, %{
        fdc_id: 171077,
        description: "Chicken, breast, meat only, cooked, roasted",
        nutrients: %{
          calories: 165,
          protein_g: 31.02,
          fat_total_g: 3.57,
          ...
        }
      }}
  """
  def get_food(fdc_id, opts \\ []) do
    api_key = opts[:api_key] || get_api_key()

    url = "#{@base_url}/food/#{fdc_id}"
    url = if api_key, do: "#{url}?api_key=#{api_key}", else: url

    case http_get(url) do
      {:ok, food} ->
        {:ok, parse_food_detail(food)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get nutrition data for multiple foods by FDC IDs.

  More efficient than calling `get_food/1` multiple times.
  """
  def get_foods(fdc_ids, opts \\ []) when is_list(fdc_ids) do
    api_key = opts[:api_key] || get_api_key()

    body = %{
      fdcIds: fdc_ids,
      nutrients: Map.values(@nutrient_ids)
    }

    url = "#{@base_url}/foods"
    url = if api_key, do: "#{url}?api_key=#{api_key}", else: url

    case http_post(url, body) do
      {:ok, foods} when is_list(foods) ->
        results = Enum.map(foods, &parse_food_detail/1)
        {:ok, results}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Search and get the best matching food's nutrition data.

  Convenience function that searches and returns the top Foundation/SR Legacy match.
  """
  def search_and_get_nutrition(query, opts \\ []) do
    case search(query, opts) do
      {:ok, []} ->
        {:error, :not_found}

      {:ok, [best | _]} ->
        get_food(best.fdc_id, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse search result into a simpler structure
  defp parse_search_result(food) do
    %{
      fdc_id: food["fdcId"],
      description: food["description"],
      data_type: food["dataType"],
      brand_owner: food["brandOwner"],
      brand_name: food["brandName"],
      score: food["score"]
    }
  end

  # Parse full food detail with nutrients
  defp parse_food_detail(food) do
    nutrients = parse_nutrients(food["foodNutrients"] || [])

    # Get serving size info if available
    {serving_value, serving_unit, serving_desc} = parse_serving_info(food)

    %{
      fdc_id: food["fdcId"],
      description: food["description"],
      data_type: food["dataType"],
      brand_owner: food["brandOwner"],
      publication_date: food["publicationDate"],
      serving_size_value: serving_value,
      serving_size_unit: serving_unit,
      serving_description: serving_desc,
      nutrients: nutrients
    }
  end

  # Parse nutrients array into a map keyed by our field names
  defp parse_nutrients(food_nutrients) do
    # Build reverse lookup: nutrient_id -> our field name
    id_to_field = Map.new(@nutrient_ids, fn {field, id} -> {id, field} end)

    Enum.reduce(food_nutrients, %{}, fn nutrient, acc ->
      nutrient_id = nutrient["nutrient"]["id"] || nutrient["nutrientId"]
      amount = nutrient["amount"] || nutrient["value"]

      case Map.get(id_to_field, nutrient_id) do
        nil -> acc
        field -> Map.put(acc, field, amount)
      end
    end)
  end

  # Parse serving size information
  defp parse_serving_info(food) do
    # USDA data is typically per 100g
    # Some foods have portion info we can use
    portions = food["foodPortions"] || []

    case portions do
      [portion | _] ->
        value = portion["gramWeight"] || 100
        unit = "g"
        desc = portion["portionDescription"] || portion["modifier"]
        {value, unit, desc}

      [] ->
        # Default to 100g (standard USDA reference)
        {100, "g", nil}
    end
  end

  # HTTP helpers
  defp http_get(url) do
    case Req.get(url, headers: [{"accept", "application/json"}]) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: 429}} ->
        Logger.warning("USDA API rate limit hit")
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        Logger.error("USDA API error: #{status} - #{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("USDA API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp http_post(url, body) do
    case Req.post(url, json: body, headers: [{"accept", "application/json"}]) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 429}} ->
        Logger.warning("USDA API rate limit hit")
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        Logger.error("USDA API error: #{status} - #{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("USDA API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_api_key do
    # Check environment variable first, then config
    System.get_env("USDA_API_KEY") || Application.get_env(:controlcopypasta, :usda_api_key)
  end

  @doc """
  Checks if API key is configured.
  """
  def api_key_configured? do
    get_api_key() != nil
  end

  @doc """
  Returns the mapping of our nutrient fields to USDA nutrient IDs.
  """
  def nutrient_ids, do: @nutrient_ids
end
