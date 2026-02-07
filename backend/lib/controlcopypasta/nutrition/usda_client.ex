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

  alias Controlcopypasta.SafeDecimal

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
  Search for foods with fallback to Branded data type.

  First tries Foundation and SR Legacy (most authoritative), then falls back
  to Branded foods if no results found.

  ## Options
  Same as search/2

  ## Examples

      iex> search_with_fallback("cheerios")
      {:ok, [%{fdc_id: ..., description: "Cheerios", data_type: "Branded", ...}]}
  """
  def search_with_fallback(query, opts \\ []) do
    # Try Foundation/SR Legacy first (most authoritative)
    case search(query, Keyword.merge(opts, data_type: ["Foundation", "SR Legacy"])) do
      {:ok, []} ->
        # Fallback to Branded if no results
        search(query, Keyword.merge(opts, data_type: ["Branded"]))

      result ->
        result
    end
  end

  @doc """
  Search and get the best matching food's nutrition data.

  Uses string similarity scoring to find the best match, not just the first result.
  Returns {:error, :not_found} if no good match is found (score < 0.5).
  """
  def search_and_get_nutrition(query, opts \\ []) do
    alias Controlcopypasta.Nutrition.StringSimilarity

    case search(query, opts) do
      {:ok, []} ->
        {:error, :not_found}

      {:ok, results} ->
        # Score each result and find the best match
        scored =
          results
          |> Enum.map(fn result ->
            score = StringSimilarity.match_score(query, result.description)
            # Bonus for Foundation/SR Legacy
            type_bonus = case result.data_type do
              "Foundation" -> 0.1
              "SR Legacy" -> 0.05
              _ -> 0
            end
            {result, score + type_bonus}
          end)
          |> Enum.filter(fn {_, score} -> score >= 0.5 end)
          |> Enum.sort_by(fn {_, score} -> -score end)

        case scored do
          [{best, _score} | _] -> get_food(best.fdc_id, opts)
          [] -> {:error, :not_found}
        end

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

  @doc """
  Extracts nutrition data from a parsed USDA food response into attrs
  suitable for IngredientNutrition creation/upsert.

  ## Parameters

  - `parsed_food` - Parsed food response from `get_food/1` or `search_and_get_nutrition/1`
  - `canonical_ingredient_id` - ID of the canonical ingredient

  ## Examples

      iex> {:ok, food} = USDAClient.search_and_get_nutrition("chicken breast")
      iex> attrs = USDAClient.extract_nutrition_from_parsed(food, ingredient.id)
      iex> Ingredients.upsert_nutrition(attrs)
  """
  def extract_nutrition_from_parsed(parsed_food, canonical_ingredient_id) do
    nutrients = parsed_food.nutrients || %{}
    fdc_id = parsed_food.fdc_id

    %{
      canonical_ingredient_id: canonical_ingredient_id,
      source: :usda,
      source_id: "#{fdc_id}",
      source_name: parsed_food.description,
      source_url: "https://fdc.nal.usda.gov/fdc-app.html#/food-details/#{fdc_id}",
      serving_size_value: Decimal.new("100"),
      serving_size_unit: "g",
      serving_description: parsed_food[:serving_description],
      calories: to_decimal(nutrients[:calories]),
      protein_g: to_decimal(nutrients[:protein_g]),
      fat_total_g: to_decimal(nutrients[:fat_total_g]),
      fat_saturated_g: to_decimal(nutrients[:fat_saturated_g]),
      fat_trans_g: to_decimal(nutrients[:fat_trans_g]),
      fat_polyunsaturated_g: to_decimal(nutrients[:fat_polyunsaturated_g]),
      fat_monounsaturated_g: to_decimal(nutrients[:fat_monounsaturated_g]),
      carbohydrates_g: to_decimal(nutrients[:carbohydrates_g]),
      fiber_g: to_decimal(nutrients[:fiber_g]),
      sugar_g: to_decimal(nutrients[:sugar_g]),
      sugar_added_g: to_decimal(nutrients[:sugar_added_g]),
      sodium_mg: to_decimal(nutrients[:sodium_mg]),
      potassium_mg: to_decimal(nutrients[:potassium_mg]),
      calcium_mg: to_decimal(nutrients[:calcium_mg]),
      iron_mg: to_decimal(nutrients[:iron_mg]),
      magnesium_mg: to_decimal(nutrients[:magnesium_mg]),
      phosphorus_mg: to_decimal(nutrients[:phosphorus_mg]),
      zinc_mg: to_decimal(nutrients[:zinc_mg]),
      vitamin_a_mcg: to_decimal(nutrients[:vitamin_a_mcg]),
      vitamin_c_mg: to_decimal(nutrients[:vitamin_c_mg]),
      vitamin_d_mcg: to_decimal(nutrients[:vitamin_d_mcg]),
      vitamin_e_mg: to_decimal(nutrients[:vitamin_e_mg]),
      vitamin_k_mcg: to_decimal(nutrients[:vitamin_k_mcg]),
      vitamin_b6_mg: to_decimal(nutrients[:vitamin_b6_mg]),
      vitamin_b12_mcg: to_decimal(nutrients[:vitamin_b12_mcg]),
      folate_mcg: to_decimal(nutrients[:folate_mcg]),
      thiamin_mg: to_decimal(nutrients[:thiamin_mg]),
      riboflavin_mg: to_decimal(nutrients[:riboflavin_mg]),
      niacin_mg: to_decimal(nutrients[:niacin_mg]),
      cholesterol_mg: to_decimal(nutrients[:cholesterol_mg]),
      water_g: to_decimal(nutrients[:water_g]),
      confidence: Decimal.new("0.95"),
      retrieved_at: DateTime.utc_now()
    }
  end

  defp to_decimal(nil), do: nil
  defp to_decimal(value) when is_number(value), do: SafeDecimal.from_number(value)
  defp to_decimal(value), do: Decimal.new("#{value}")

  @doc """
  Extracts density data from USDA foodPortions.
  Returns list of maps ready for IngredientDensity creation.

  ## Parameters

  - `food_response` - Parsed food response from USDA API (get_food/1 result)
  - `canonical_ingredient_id` - ID of the canonical ingredient

  ## Examples

      iex> {:ok, food} = USDAClient.get_food(171287)
      iex> densities = USDAClient.extract_densities(food, ingredient.id)
      [%{volume_unit: "cup", grams_per_unit: 140.0, source: "usda", ...}, ...]
  """
  def extract_densities(food_response, canonical_ingredient_id) do
    fdc_id = food_response[:fdc_id] || food_response["fdcId"]

    # Get raw food data - need to fetch again if we only have parsed data
    # For now, assume we're getting the raw response
    portions = get_portions_from_response(food_response)

    portions
    |> Enum.map(fn portion ->
      volume_unit = normalize_volume_unit(portion["portionDescription"] || portion["modifier"])
      grams = portion["gramWeight"]

      if volume_unit && grams && grams > 0 do
        %{
          canonical_ingredient_id: canonical_ingredient_id,
          volume_unit: volume_unit,
          grams_per_unit: grams,
          preparation: extract_preparation(portion["modifier"]),
          source: "usda",
          source_id: "#{fdc_id}:#{portion["id"]}",
          source_url: "https://fdc.nal.usda.gov/fdc-app.html#/food-details/#{fdc_id}",
          confidence: calculate_usda_confidence(portion),
          data_points: portion["dataPoints"],
          retrieved_at: DateTime.utc_now(),
          notes: portion["portionDescription"]
        }
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp get_portions_from_response(%{} = response) when is_map(response) do
    # Handle both atom-keyed (from parse_food_detail) and string-keyed (raw) responses
    response["foodPortions"] || response[:food_portions] || []
  end

  @doc """
  Extracts densities from raw USDA API response (before parse_food_detail).
  Use this when you have the raw API response.
  """
  def extract_densities_from_raw(raw_response, canonical_ingredient_id) do
    fdc_id = raw_response["fdcId"]
    portions = raw_response["foodPortions"] || []

    portions
    |> Enum.map(fn portion ->
      volume_unit = normalize_volume_unit(portion["portionDescription"] || portion["modifier"])
      grams = portion["gramWeight"]

      if volume_unit && grams && grams > 0 do
        %{
          canonical_ingredient_id: canonical_ingredient_id,
          volume_unit: volume_unit,
          grams_per_unit: grams,
          preparation: extract_preparation(portion["modifier"]),
          source: "usda",
          source_id: "#{fdc_id}:#{portion["id"]}",
          source_url: "https://fdc.nal.usda.gov/fdc-app.html#/food-details/#{fdc_id}",
          confidence: calculate_usda_confidence(portion),
          data_points: portion["dataPoints"],
          retrieved_at: DateTime.utc_now(),
          notes: portion["portionDescription"]
        }
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Fetches a food and returns both parsed nutrition data and raw response for density extraction.
  """
  def get_food_with_raw(fdc_id, opts \\ []) do
    api_key = opts[:api_key] || get_api_key()

    url = "#{@base_url}/food/#{fdc_id}"
    url = if api_key, do: "#{url}?api_key=#{api_key}", else: url

    case http_get(url) do
      {:ok, raw_food} ->
        {:ok, %{parsed: parse_food_detail(raw_food), raw: raw_food}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Normalize USDA portion descriptions to standard volume units
  defp normalize_volume_unit(nil), do: nil

  defp normalize_volume_unit(description) when is_binary(description) do
    desc = String.downcase(description)

    cond do
      String.contains?(desc, "cup") -> "cup"
      String.contains?(desc, "tablespoon") or String.contains?(desc, "tbsp") -> "tbsp"
      String.contains?(desc, "teaspoon") or String.contains?(desc, "tsp") -> "tsp"
      String.contains?(desc, "fl oz") or String.contains?(desc, "fluid ounce") -> "fl oz"
      String.contains?(desc, "pint") -> "pint"
      String.contains?(desc, "quart") -> "quart"
      String.contains?(desc, "gallon") -> "gallon"
      String.contains?(desc, "ml") or String.contains?(desc, "milliliter") -> "ml"
      String.contains?(desc, "liter") -> "liter"
      Regex.match?(~r/\b(medium|large|small|whole|piece|unit|each)\b/, desc) -> "each"
      true -> nil
    end
  end

  # Extract preparation method from modifier
  defp extract_preparation(nil), do: nil

  defp extract_preparation(modifier) when is_binary(modifier) do
    mod = String.downcase(modifier)

    cond do
      String.contains?(mod, "packed") -> "packed"
      String.contains?(mod, "sifted") -> "sifted"
      String.contains?(mod, "chopped") -> "chopped"
      String.contains?(mod, "diced") -> "diced"
      String.contains?(mod, "minced") -> "minced"
      String.contains?(mod, "sliced") -> "sliced"
      String.contains?(mod, "grated") -> "grated"
      String.contains?(mod, "shredded") -> "shredded"
      true -> nil
    end
  end

  # Calculate confidence based on USDA data quality
  defp calculate_usda_confidence(portion) do
    # Base confidence 0.95 for USDA, adjusted by data points
    base = 0.95
    points = portion["dataPoints"] || 1

    confidence =
      cond do
        points >= 10 -> base
        points >= 5 -> base - 0.05
        points >= 2 -> base - 0.10
        true -> base - 0.15
      end

    SafeDecimal.from_number(confidence)
  end
end
