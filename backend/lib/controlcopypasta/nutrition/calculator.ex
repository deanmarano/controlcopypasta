defmodule Controlcopypasta.Nutrition.Calculator do
  @moduledoc """
  Calculates recipe nutrition by summing the nutrition of individual ingredients.

  ## Process

  1. Parse each ingredient with the Ingredients.Parser
  2. Match to canonical ingredient (already done by parser)
  3. Convert quantity to grams via DensityConverter
  4. Look up nutrition per 100g from IngredientNutrition
  5. Scale: (grams / 100) * nutrition_value
  6. Sum all ingredients
  7. Divide by servings for per-serving values

  ## Return Structure

  ```elixir
  %{
    total: %{calories: 1200, protein_g: 45, ...},
    per_serving: %{calories: 300, protein_g: 11.25, ...},
    servings: 4,
    completeness: 0.85,  # 85% of ingredients calculated
    ingredients: [
      %{original: "2 cups flour", status: :calculated, calories: 910, grams: 250},
      %{original: "1 sprig rosemary", status: :no_nutrition, calories: nil, grams: nil}
    ],
    warnings: ["Some ingredients could not be calculated"]
  }
  ```
  """

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.{TokenParser, IngredientNutrition}
  alias Controlcopypasta.Nutrition.{DensityConverter, Range}
  alias Controlcopypasta.Recipes.Recipe

  # Nutrient fields we calculate
  @nutrient_fields [
    :calories,
    :protein_g,
    :fat_total_g,
    :fat_saturated_g,
    :carbohydrates_g,
    :fiber_g,
    :sugar_g,
    :sodium_mg,
    :cholesterol_mg,
    :potassium_mg,
    :calcium_mg,
    :iron_mg,
    :vitamin_a_mcg,
    :vitamin_c_mg,
    :vitamin_d_mcg
  ]

  @doc """
  Calculates nutrition for a recipe.

  ## Options

  - `:servings_override` - Override the recipe's serving count

  ## Returns

  A map with total nutrition, per-serving nutrition, and detailed ingredient breakdown.
  """
  def calculate_recipe_nutrition(%Recipe{} = recipe, opts \\ []) do
    servings = parse_servings(Keyword.get(opts, :servings_override) || recipe.servings)

    # Build ingredient lookup for efficient parsing
    lookup = Ingredients.build_ingredient_lookup()

    # Process each ingredient
    ingredient_results =
      recipe.ingredients
      |> Enum.map(&process_ingredient(&1, lookup))

    # Calculate totals
    totals = sum_nutrients(ingredient_results)

    # Calculate per-serving
    per_serving = divide_nutrients(totals, servings)

    # Calculate completeness
    {calculated_count, total_count} = count_calculated(ingredient_results)
    completeness = if total_count > 0, do: calculated_count / total_count, else: 0.0

    # Generate warnings
    warnings = generate_warnings(ingredient_results, completeness)

    %{
      total: format_nutrients_map(totals),
      per_serving: format_nutrients_map(per_serving),
      servings: servings,
      completeness: Float.round(completeness, 2),
      ingredients: Enum.map(ingredient_results, &format_ingredient_result/1),
      warnings: warnings
    }
  end

  # Format all nutrients in a map
  defp format_nutrients_map(nutrients) do
    nutrients
    |> Enum.map(fn {field, value} ->
      formatted = case value do
        %Range{best: nil} -> nil
        %Range{} = range -> format_range_or_value(range)
        nil -> nil
        num when is_number(num) -> num
      end
      {field, formatted}
    end)
    |> Map.new()
  end

  @doc """
  Calculates nutrition for a single ingredient text.

  Useful for testing or ad-hoc calculations.
  """
  def calculate_ingredient_nutrition(ingredient_text, opts \\ []) do
    lookup = Keyword.get_lazy(opts, :lookup, fn -> Ingredients.build_ingredient_lookup() end)

    ingredient_map = %{"text" => ingredient_text}
    process_ingredient(ingredient_map, lookup)
  end

  # Process a single ingredient map
  defp process_ingredient(%{"text" => text}, lookup) do
    # Parse the ingredient using TokenParser
    parsed = TokenParser.parse(text, lookup: lookup)

    # Extract canonical info from primary_ingredient
    primary = parsed.primary_ingredient
    canonical_id = if primary, do: primary.canonical_id, else: nil
    canonical_name = if primary, do: primary.canonical_name, else: nil

    result = %{
      original: text,
      parsed: parsed,
      canonical_id: canonical_id,
      canonical_name: canonical_name,
      status: nil,
      grams: nil,
      nutrients: empty_nutrients(),
      error: nil
    }

    # Check if we have a canonical match
    cond do
      is_nil(canonical_id) ->
        %{result | status: :no_match, error: "Could not match to canonical ingredient"}

      is_nil(parsed.quantity) ->
        %{result | status: :no_quantity, error: "No quantity found"}

      true ->
        calculate_ingredient_nutrients(result, parsed, canonical_id, canonical_name)
    end
  end

  defp process_ingredient(_ingredient_map, _lookup) do
    %{
      original: "",
      parsed: nil,
      canonical_id: nil,
      canonical_name: nil,
      status: :invalid,
      grams: nil,
      nutrients: empty_nutrients(),
      error: "Invalid ingredient format"
    }
  end

  defp calculate_ingredient_nutrients(result, parsed, canonical_id, canonical_name) do
    # Get the canonical ingredient for category info
    canonical = Ingredients.get_canonical_ingredient(canonical_id)
    category = if canonical, do: canonical.category, else: nil

    # Convert to grams range (accounts for quantity ranges and density variation)
    preparation = List.first(parsed.preparations || [])

    case DensityConverter.to_grams_range(
           canonical_id,
           parsed.quantity,
           parsed.quantity_min,
           parsed.quantity_max,
           parsed.unit,
           preparation: preparation,
           category: category,
           canonical_name: canonical_name
         ) do
      {:ok, grams_range} ->
        # Look up nutrition data
        case Ingredients.get_nutrition(canonical_id) do
          {:ok, nutrition} ->
            # Scale nutrients with range propagation
            nutrients = scale_nutrients_with_range(nutrition, grams_range)
            %{result |
              status: :calculated,
              grams: Range.round_range(grams_range, 1),
              nutrients: nutrients
            }

          {:error, :not_found} ->
            %{result |
              status: :no_nutrition,
              grams: Range.round_range(grams_range, 1),
              error: "No nutrition data available"
            }
        end

      {:error, :no_density} ->
        # We might have nutrition but no density - try alternate method
        case try_nutrition_with_weight_unit_range(result, parsed, canonical_id) do
          {:ok, updated_result} -> updated_result
          :error ->
            %{result | status: :no_density, error: "No density data to convert volume to grams"}
        end

      {:error, :no_count_density} ->
        # Same fallback for count items
        case try_nutrition_with_weight_unit_range(result, parsed, canonical_id) do
          {:ok, updated_result} -> updated_result
          :error ->
            %{result | status: :no_density, error: "No density data for count item"}
        end

      {:error, reason} ->
        %{result | status: :error, error: "Conversion error: #{inspect(reason)}"}
    end
  end

  # If the unit is already a weight unit, we don't need density
  defp try_nutrition_with_weight_unit_range(result, parsed, canonical_id) do
    if DensityConverter.weight_unit?(parsed.unit) do
      case DensityConverter.to_grams_range(
             canonical_id,
             parsed.quantity,
             parsed.quantity_min,
             parsed.quantity_max,
             parsed.unit
           ) do
        {:ok, grams_range} ->
          case Ingredients.get_nutrition(canonical_id) do
            {:ok, nutrition} ->
              nutrients = scale_nutrients_with_range(nutrition, grams_range)
              {:ok, %{result |
                status: :calculated,
                grams: Range.round_range(grams_range, 1),
                nutrients: nutrients
              }}

            {:error, _} ->
              :error
          end

        _ ->
          :error
      end
    else
      :error
    end
  end

  # Scale nutrition values with range propagation
  # Takes a grams range and returns nutrient ranges
  defp scale_nutrients_with_range(%IngredientNutrition{} = nutrition, %Range{} = grams_range) do
    serving_size = Decimal.to_float(nutrition.serving_size_value)

    # Get the confidence from nutrition source
    nutrition_confidence = get_nutrition_confidence(nutrition)

    @nutrient_fields
    |> Enum.map(fn field ->
      value = Map.get(nutrition, field)

      range =
        if value do
          base_per_serving = Decimal.to_float(value)

          # Calculate scaled values for min/best/max grams
          scaled_range = Range.from_range(
            (grams_range.min / serving_size) * base_per_serving,
            (grams_range.best / serving_size) * base_per_serving,
            (grams_range.max / serving_size) * base_per_serving,
            grams_range.confidence * nutrition_confidence
          )

          Range.round_range(scaled_range, 2)
        else
          Range.from_single(nil, 0.0)
        end

      {field, range}
    end)
    |> Map.new()
  end

  # Get confidence from nutrition source
  defp get_nutrition_confidence(%IngredientNutrition{} = nutrition) do
    case nutrition.confidence do
      %Decimal{} = conf -> Decimal.to_float(conf)
      conf when is_float(conf) -> conf
      conf when is_integer(conf) -> conf * 1.0
      nil ->
        # Fallback based on source
        case nutrition.source do
          :usda -> 0.95
          :manual -> 0.85
          :fatsecret -> 0.80
          :open_food_facts -> 0.70
          :nutritionix -> 0.75
          :estimated -> 0.30
          _ -> 0.50
        end
    end
  end

  # Sum nutrients across all ingredients (handles both Range and scalar values)
  defp sum_nutrients(ingredient_results) do
    @nutrient_fields
    |> Enum.map(fn field ->
      ranges =
        ingredient_results
        |> Enum.map(fn r -> get_in(r, [:nutrients, field]) end)
        |> Enum.filter(fn
          %Range{best: nil} -> false
          %Range{} -> true
          nil -> false
          _ -> false
        end)

      sum_range =
        if Enum.empty?(ranges) do
          Range.from_single(0, 1.0)
        else
          Range.sum_ranges(ranges)
          |> Range.round_range(2)
        end

      {field, sum_range}
    end)
    |> Map.new()
  end

  # Divide nutrients by servings (handles Range values)
  defp divide_nutrients(totals, servings) when servings > 0 do
    totals
    |> Enum.map(fn {field, value} ->
      divided =
        case value do
          %Range{} = range -> Range.divide(range, servings) |> Range.round_range(2)
          nil -> nil
          num when is_number(num) -> round_number(num / servings, 2)
        end
      {field, divided}
    end)
    |> Map.new()
  end

  defp divide_nutrients(totals, _), do: totals

  # Round a number to specified decimals, handling both integers and floats
  defp round_number(value, _decimals) when is_integer(value) do
    value * 1.0
  end

  defp round_number(value, decimals) when is_float(value) do
    Float.round(value, decimals)
  end

  defp empty_nutrients do
    @nutrient_fields
    |> Enum.map(&{&1, Range.from_single(nil, 0.0)})
    |> Map.new()
  end

  defp count_calculated(results) do
    total = length(results)

    calculated =
      results
      |> Enum.count(fn r -> r.status == :calculated end)

    {calculated, total}
  end

  defp generate_warnings(results, completeness) do
    warnings = []

    warnings =
      if completeness < 1.0 do
        uncalculated = Enum.count(results, fn r -> r.status != :calculated end)
        ["#{uncalculated} ingredient(s) could not be calculated" | warnings]
      else
        warnings
      end

    # Check for specific issues
    no_match = Enum.count(results, fn r -> r.status == :no_match end)
    no_density = Enum.count(results, fn r -> r.status == :no_density end)
    no_nutrition = Enum.count(results, fn r -> r.status == :no_nutrition end)

    warnings =
      if no_match > 0 do
        ["#{no_match} ingredient(s) could not be identified" | warnings]
      else
        warnings
      end

    warnings =
      if no_density > 0 do
        ["#{no_density} ingredient(s) missing density data for volume conversion" | warnings]
      else
        warnings
      end

    warnings =
      if no_nutrition > 0 do
        ["#{no_nutrition} ingredient(s) have no nutrition data" | warnings]
      else
        warnings
      end

    Enum.reverse(warnings)
  end

  defp format_ingredient_result(result) do
    grams = format_range_or_value(result.grams)
    parsed = result.parsed

    %{
      original: result.original,
      status: result.status,
      canonical_name: result.canonical_name,
      canonical_id: result.canonical_id,
      quantity: if(parsed, do: parsed.quantity, else: nil),
      quantity_min: if(parsed, do: parsed.quantity_min, else: nil),
      quantity_max: if(parsed, do: parsed.quantity_max, else: nil),
      unit: if(parsed, do: parsed.unit, else: nil),
      grams: grams,
      calories: format_nutrient_range(get_in(result, [:nutrients, :calories])),
      protein_g: format_nutrient_range(get_in(result, [:nutrients, :protein_g])),
      carbohydrates_g: format_nutrient_range(get_in(result, [:nutrients, :carbohydrates_g])),
      fat_total_g: format_nutrient_range(get_in(result, [:nutrients, :fat_total_g])),
      error: result.error
    }
  end

  # Format a Range to a map for JSON serialization
  defp format_range_or_value(%Range{} = range) do
    %{
      min: range.min,
      best: range.best,
      max: range.max,
      confidence: range.confidence
    }
  end

  defp format_range_or_value(value), do: value

  defp format_nutrient_range(%Range{best: nil}), do: nil
  defp format_nutrient_range(%Range{} = range), do: format_range_or_value(range)
  defp format_nutrient_range(nil), do: nil
  defp format_nutrient_range(value) when is_number(value), do: value

  defp parse_servings(nil), do: 1
  defp parse_servings(servings) when is_integer(servings), do: max(servings, 1)
  defp parse_servings(servings) when is_float(servings), do: max(trunc(servings), 1)

  defp parse_servings(servings) when is_binary(servings) do
    # Handle various serving formats: "4", "4 servings", "4-6", "serves 4"
    servings
    |> String.downcase()
    |> String.replace(~r/[^\d\-]/, " ")
    |> String.split()
    |> List.first()
    |> parse_serving_number()
  end

  defp parse_servings(_), do: 1

  defp parse_serving_number(nil), do: 1

  defp parse_serving_number(str) do
    case Integer.parse(str) do
      {num, _} -> max(num, 1)
      :error -> 1
    end
  end

  @doc """
  Returns the list of nutrient fields calculated.
  """
  def nutrient_fields, do: @nutrient_fields
end
