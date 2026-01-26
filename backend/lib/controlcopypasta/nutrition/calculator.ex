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
  alias Controlcopypasta.Ingredients.{Parser, IngredientNutrition}
  alias Controlcopypasta.Nutrition.DensityConverter
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
      total: totals,
      per_serving: per_serving,
      servings: servings,
      completeness: Float.round(completeness, 2),
      ingredients: Enum.map(ingredient_results, &format_ingredient_result/1),
      warnings: warnings
    }
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
    # Parse the ingredient
    parsed = Parser.parse(text, lookup: lookup)

    result = %{
      original: text,
      parsed: parsed,
      status: nil,
      grams: nil,
      nutrients: empty_nutrients(),
      error: nil
    }

    # Check if we have a canonical match
    cond do
      is_nil(parsed.canonical_id) ->
        %{result | status: :no_match, error: "Could not match to canonical ingredient"}

      is_nil(parsed.quantity) ->
        %{result | status: :no_quantity, error: "No quantity found"}

      true ->
        calculate_ingredient_nutrients(result, parsed)
    end
  end

  defp process_ingredient(_ingredient_map, _lookup) do
    %{
      original: "",
      parsed: nil,
      status: :invalid,
      grams: nil,
      nutrients: empty_nutrients(),
      error: "Invalid ingredient format"
    }
  end

  defp calculate_ingredient_nutrients(result, parsed) do
    # Get the canonical ingredient for category info
    canonical = Ingredients.get_canonical_ingredient(parsed.canonical_id)
    category = if canonical, do: canonical.category, else: nil

    # Convert to grams
    preparation = List.first(parsed.preparations)

    case DensityConverter.to_grams(
           parsed.canonical_id,
           parsed.quantity,
           parsed.unit,
           preparation: preparation,
           category: category
         ) do
      {:ok, grams} ->
        # Look up nutrition data
        case Ingredients.get_nutrition(parsed.canonical_id) do
          {:ok, nutrition} ->
            nutrients = scale_nutrients(nutrition, grams)
            %{result | status: :calculated, grams: Float.round(grams, 1), nutrients: nutrients}

          {:error, :not_found} ->
            %{result |
              status: :no_nutrition,
              grams: Float.round(grams, 1),
              error: "No nutrition data available"
            }
        end

      {:error, :no_density} ->
        # We might have nutrition but no density - try alternate method
        case try_nutrition_with_weight_unit(result, parsed) do
          {:ok, updated_result} -> updated_result
          :error ->
            %{result | status: :no_density, error: "No density data to convert volume to grams"}
        end

      {:error, reason} ->
        %{result | status: :error, error: "Conversion error: #{inspect(reason)}"}
    end
  end

  # If the unit is already a weight unit, we don't need density
  defp try_nutrition_with_weight_unit(result, parsed) do
    if DensityConverter.weight_unit?(parsed.unit) do
      case DensityConverter.to_grams(parsed.canonical_id, parsed.quantity, parsed.unit) do
        {:ok, grams} ->
          case Ingredients.get_nutrition(parsed.canonical_id) do
            {:ok, nutrition} ->
              nutrients = scale_nutrients(nutrition, grams)
              {:ok, %{result | status: :calculated, grams: Float.round(grams, 1), nutrients: nutrients}}

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

  # Scale nutrition values from per-100g to actual grams
  defp scale_nutrients(%IngredientNutrition{} = nutrition, grams) do
    serving_size = Decimal.to_float(nutrition.serving_size_value)
    scale_factor = grams / serving_size

    @nutrient_fields
    |> Enum.map(fn field ->
      value = Map.get(nutrition, field)
      scaled = if value, do: Float.round(Decimal.to_float(value) * scale_factor, 2), else: nil
      {field, scaled}
    end)
    |> Map.new()
  end

  # Sum nutrients across all ingredients
  defp sum_nutrients(ingredient_results) do
    @nutrient_fields
    |> Enum.map(fn field ->
      sum =
        ingredient_results
        |> Enum.map(fn r -> get_in(r, [:nutrients, field]) end)
        |> Enum.filter(&(&1 != nil))
        |> Enum.sum()

      {field, round_number(sum, 2)}
    end)
    |> Map.new()
  end

  # Divide nutrients by servings
  defp divide_nutrients(totals, servings) when servings > 0 do
    totals
    |> Enum.map(fn {field, value} ->
      {field, if(value, do: round_number(value / servings, 2), else: nil)}
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
    |> Enum.map(&{&1, nil})
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
    %{
      original: result.original,
      status: result.status,
      canonical_name: get_in(result, [:parsed, Access.key(:canonical_name)]),
      canonical_id: get_in(result, [:parsed, Access.key(:canonical_id)]),
      quantity: get_in(result, [:parsed, Access.key(:quantity)]),
      unit: get_in(result, [:parsed, Access.key(:unit)]),
      grams: result.grams,
      calories: get_in(result, [:nutrients, :calories]),
      protein_g: get_in(result, [:nutrients, :protein_g]),
      carbohydrates_g: get_in(result, [:nutrients, :carbohydrates_g]),
      fat_total_g: get_in(result, [:nutrients, :fat_total_g]),
      error: result.error
    }
  end

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
