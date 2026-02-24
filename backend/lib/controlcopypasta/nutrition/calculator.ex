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

  alias Controlcopypasta.{Ingredients, SafeDecimal}
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

  # Valid nutrition sources
  @valid_sources [
    :composite,
    :usda,
    :manual,
    :fatsecret,
    :open_food_facts,
    :nutritionix,
    :estimated
  ]

  @doc """
  Calculates nutrition for a recipe.

  ## Options

  - `:servings_override` - Override the recipe's serving count
  - `:source` - Nutrition source to use (default: `:composite`)
    - `:composite` - Weighted average of all available sources (recommended)
    - `:usda`, `:fatsecret`, etc. - Use specific source only

  ## Returns

  A map with total nutrition, per-serving nutrition, and detailed ingredient breakdown.
  """
  def calculate_recipe_nutrition(%Recipe{} = recipe, opts \\ []) do
    servings = parse_servings(Keyword.get(opts, :servings_override) || recipe.servings)
    source = Keyword.get(opts, :source, :composite)

    # Build ingredient lookup for efficient parsing
    lookup = Ingredients.build_ingredient_lookup()

    # Process each ingredient with source selection
    ingredient_results =
      recipe.ingredients
      |> Enum.map(&process_ingredient(&1, lookup, source))

    # Calculate totals
    totals = sum_nutrients(ingredient_results)

    # Calculate per-serving
    per_serving = divide_nutrients(totals, servings)

    # Calculate completeness
    {calculated_count, total_count} = count_calculated(ingredient_results)
    completeness = if total_count > 0, do: calculated_count / total_count, else: 0.0

    # Generate warnings
    warnings = generate_warnings(ingredient_results, completeness)

    # Collect available sources across all ingredients
    available_sources = collect_available_sources(ingredient_results)

    %{
      total: format_nutrients_map(totals),
      per_serving: format_nutrients_map(per_serving),
      servings: servings,
      completeness: Float.round(completeness, 2),
      source_used: source,
      available_sources: available_sources,
      ingredients: Enum.map(ingredient_results, &format_ingredient_result/1),
      warnings: warnings
    }
  end

  @doc """
  Returns the list of valid nutrition sources.
  """
  def valid_sources, do: @valid_sources

  # Format all nutrients in a map
  defp format_nutrients_map(nutrients) do
    nutrients
    |> Enum.map(fn {field, value} ->
      formatted =
        case value do
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

  ## Options

  - `:lookup` - Pre-built ingredient lookup map
  - `:source` - Nutrition source to use (default: `:composite`)
  """
  def calculate_ingredient_nutrition(ingredient_text, opts \\ []) do
    lookup = Keyword.get_lazy(opts, :lookup, fn -> Ingredients.build_ingredient_lookup() end)
    source = Keyword.get(opts, :source, :composite)

    ingredient_map = %{"text" => ingredient_text}
    process_ingredient(ingredient_map, lookup, source)
  end

  # Process a single ingredient map
  defp process_ingredient(%{"text" => text}, lookup, source) do
    # Parse the ingredient using TokenParser
    parsed = TokenParser.parse(text, lookup: lookup)

    # Extract canonical info from primary_ingredient
    primary = parsed.primary_ingredient
    canonical_id = if primary, do: primary.canonical_id, else: nil
    canonical_name = if primary, do: primary.canonical_name, else: nil

    # Get available sources for this ingredient
    available_sources =
      if canonical_id do
        Ingredients.list_nutrition_sources(canonical_id)
        |> Enum.map(fn n ->
          %{
            source: n.source,
            confidence: decimal_to_float(n.confidence),
            is_primary: n.is_primary
          }
        end)
      else
        []
      end

    result = %{
      original: text,
      parsed: parsed,
      canonical_id: canonical_id,
      canonical_name: canonical_name,
      status: nil,
      grams: nil,
      nutrients: empty_nutrients(),
      error: nil,
      measurement_type: nil,
      conversion_method: nil,
      source_used: nil,
      available_sources: available_sources
    }

    # Check if we have a canonical match
    cond do
      is_nil(canonical_id) ->
        %{result | status: :no_match, error: "Could not match to canonical ingredient"}

      is_nil(parsed.quantity) ->
        %{result | status: :no_quantity, error: "No quantity found"}

      true ->
        calculate_ingredient_nutrients(result, parsed, canonical_id, canonical_name, source)
    end
  end

  defp process_ingredient(_ingredient_map, _lookup, _source) do
    %{
      original: "",
      parsed: nil,
      canonical_id: nil,
      canonical_name: nil,
      status: :invalid,
      grams: nil,
      nutrients: empty_nutrients(),
      error: "Invalid ingredient format",
      measurement_type: nil,
      conversion_method: nil,
      source_used: nil,
      available_sources: []
    }
  end

  # Helper to convert Decimal to float safely
  defp decimal_to_float(nil), do: nil
  defp decimal_to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp decimal_to_float(f) when is_float(f), do: f
  defp decimal_to_float(i) when is_integer(i), do: i * 1.0

  defp calculate_ingredient_nutrients(result, parsed, canonical_id, canonical_name, source) do
    # Get the canonical ingredient for category and measurement_type info
    canonical = Ingredients.get_canonical_ingredient(canonical_id)
    category = if canonical, do: canonical.category, else: nil
    measurement_type = if canonical, do: canonical.measurement_type, else: "standard"

    # Add measurement_type to result
    result = %{result | measurement_type: measurement_type}

    # Resolve effective unit: if no unit but container present, use container info
    {effective_qty, effective_qty_min, effective_qty_max, effective_unit} =
      resolve_effective_unit(parsed)

    # Determine conversion method based on unit type
    conversion_method = determine_conversion_method(effective_unit, measurement_type)

    # Convert to grams range (accounts for quantity ranges and density variation)
    preparation = List.first(parsed.preparations || [])

    case DensityConverter.to_grams_range(
           canonical_id,
           effective_qty,
           effective_qty_min,
           effective_qty_max,
           effective_unit,
           preparation: preparation,
           category: category,
           canonical_name: canonical_name,
           measurement_type: measurement_type
         ) do
      {:ok, grams_range} ->
        # Look up nutrition data based on source
        case get_nutrition_for_source(canonical_id, source) do
          {:ok, nutrition, source_used} ->
            # Scale nutrients with range propagation
            nutrients = scale_nutrients_with_range(nutrition, grams_range)

            %{
              result
              | status: :calculated,
                grams: Range.round_range(grams_range, 1),
                nutrients: nutrients,
                conversion_method: conversion_method,
                source_used: source_used
            }

          {:error, :not_found} ->
            %{
              result
              | status: :no_nutrition,
                grams: Range.round_range(grams_range, 1),
                error: "No nutrition data available",
                conversion_method: conversion_method
            }
        end

      {:error, :no_density} ->
        # We might have nutrition but no density - try alternate method
        case try_nutrition_with_weight_unit_range(result, parsed, canonical_id, source) do
          {:ok, updated_result} ->
            updated_result

          :error ->
            %{result | status: :no_density, error: "No density data to convert volume to grams"}
        end

      {:error, :no_count_density} ->
        # Same fallback for count items
        case try_nutrition_with_weight_unit_range(result, parsed, canonical_id, source) do
          {:ok, updated_result} ->
            updated_result

          :error ->
            %{result | status: :no_density, error: "No density data for count item"}
        end

      {:error, :volume_not_recommended} ->
        # Weight-primary ingredient used with volume unit - warn but try weight fallback
        case try_nutrition_with_weight_unit_range(result, parsed, canonical_id, source) do
          {:ok, updated_result} ->
            updated_result

          :error ->
            %{
              result
              | status: :no_density,
                error: "This ingredient is typically measured by weight, not volume"
            }
        end

      {:error, reason} ->
        %{result | status: :error, error: "Conversion error: #{inspect(reason)}"}
    end
  end

  # Get nutrition for a specific source, or composite if requested
  defp get_nutrition_for_source(canonical_id, :composite) do
    sources = Ingredients.list_nutrition_sources(canonical_id)

    if Enum.empty?(sources) do
      {:error, :not_found}
    else
      composite = composite_nutrition(sources)
      {:ok, composite, :composite}
    end
  end

  defp get_nutrition_for_source(canonical_id, source) when is_atom(source) do
    case Ingredients.get_nutrition_by_source(canonical_id, source) do
      nil ->
        # Fall back to primary source if specific source not available
        case Ingredients.get_nutrition(canonical_id) do
          {:ok, nutrition} -> {:ok, nutrition, nutrition.source}
          {:error, :not_found} -> {:error, :not_found}
        end

      nutrition ->
        {:ok, nutrition, source}
    end
  end

  # Calculate weighted average nutrition across multiple sources
  defp composite_nutrition(sources) when is_list(sources) do
    # Calculate total confidence for weighting
    raw_confidence =
      sources
      |> Enum.map(&(decimal_to_float(&1.confidence) || 0.5))
      |> Enum.sum()

    # If no confidence data, use equal weights
    _total_confidence = if raw_confidence == +0.0, do: length(sources) * 0.5, else: raw_confidence

    # Build a composite IngredientNutrition struct with weighted averages
    # First, get the serving size from the first source (they should all use the same reference)
    first_source = hd(sources)

    # Calculate weighted average for each nutrient field
    nutrient_fields = IngredientNutrition.all_nutrient_fields()

    weighted_nutrients =
      nutrient_fields
      |> Enum.map(fn field ->
        weighted_value =
          sources
          |> Enum.reduce({0.0, 0.0}, fn source, {sum, weight_sum} ->
            value = Map.get(source, field)
            confidence = decimal_to_float(source.confidence) || 0.5

            if value do
              value_float = decimal_to_float(value)
              {sum + value_float * confidence, weight_sum + confidence}
            else
              {sum, weight_sum}
            end
          end)
          |> case do
            {_, ws} when ws == 0.0 -> nil
            {sum, weight_sum} -> SafeDecimal.from_number(sum / weight_sum)
          end

        {field, weighted_value}
      end)
      |> Map.new()

    # Calculate composite confidence (weighted average of source confidences)
    composite_confidence =
      sources
      |> Enum.map(&(decimal_to_float(&1.confidence) || 0.5))
      |> then(fn confidences ->
        if Enum.empty?(confidences) do
          Decimal.new("0.5")
        else
          avg = Enum.sum(confidences) / length(confidences)
          SafeDecimal.from_number(avg)
        end
      end)

    # Build composite struct
    %IngredientNutrition{
      canonical_ingredient_id: first_source.canonical_ingredient_id,
      # Mark as composite/estimated
      source: :estimated,
      serving_size_value: first_source.serving_size_value,
      serving_size_unit: first_source.serving_size_unit,
      is_primary: false,
      confidence: composite_confidence
    }
    |> Map.merge(weighted_nutrients)
  end

  # Collect unique available sources across all ingredients
  defp collect_available_sources(ingredient_results) do
    ingredient_results
    |> Enum.flat_map(fn r -> r.available_sources || [] end)
    |> Enum.reduce(%{}, fn source_info, acc ->
      # Keep the highest confidence for each source type
      key = source_info.source
      existing = Map.get(acc, key)

      if is_nil(existing) || (source_info.confidence || 0) > (existing.confidence || 0) do
        Map.put(acc, key, source_info)
      else
        acc
      end
    end)
    |> Map.values()
    |> Enum.sort_by(fn s -> -(s.confidence || 0) end)
  end

  # Resolve effective unit from parsed ingredient
  # When unit is nil but a container is present, use container info for conversion
  defp resolve_effective_unit(parsed) do
    qty = parsed.quantity
    qty_min = parsed.quantity_min
    qty_max = parsed.quantity_max
    unit = parsed.unit

    cond do
      # Already has a unit - use as-is
      not is_nil(unit) ->
        {qty, qty_min, qty_max, unit}

      # No unit but container with size info (e.g., "1 (15-oz) can chickpeas")
      # Convert using: quantity * container_size in container_size_unit
      not is_nil(parsed.container) and not is_nil(parsed.container.size_value) and
          not is_nil(parsed.container.size_unit) ->
        # Multiply quantity by container size (e.g., 2 cans × 15 oz = 30 oz)
        size_val = parsed.container.size_value
        total_qty = (qty || 1.0) * size_val
        total_min = (qty_min || qty || 1.0) * size_val
        total_max = (qty_max || qty || 1.0) * size_val
        {total_qty, total_min, total_max, parsed.container.size_unit}

      # No unit but container type only (e.g., "1 can chickpeas")
      # Use container_type as the count unit for density lookup
      not is_nil(parsed.container) ->
        {qty, qty_min, qty_max, parsed.container.container_type}

      # No unit, no container - plain count item
      true ->
        {qty, qty_min, qty_max, nil}
    end
  end

  # Determine the conversion method based on unit type and measurement_type
  defp determine_conversion_method(unit, measurement_type) do
    cond do
      is_nil(unit) ->
        "count"

      DensityConverter.weight_unit?(unit) ->
        "weight"

      DensityConverter.count_unit?(unit) ->
        "count"

      DensityConverter.volume_unit?(unit) ->
        case measurement_type do
          "liquid" -> "liquid_density"
          _ -> "volume_density"
        end

      true ->
        "unknown"
    end
  end

  # If the unit is already a weight unit, we don't need density
  defp try_nutrition_with_weight_unit_range(result, parsed, canonical_id, source) do
    if DensityConverter.weight_unit?(parsed.unit) do
      case DensityConverter.to_grams_range(
             canonical_id,
             parsed.quantity,
             parsed.quantity_min,
             parsed.quantity_max,
             parsed.unit
           ) do
        {:ok, grams_range} ->
          case get_nutrition_for_source(canonical_id, source) do
            {:ok, nutrition, source_used} ->
              nutrients = scale_nutrients_with_range(nutrition, grams_range)

              {:ok,
               %{
                 result
                 | status: :calculated,
                   grams: Range.round_range(grams_range, 1),
                   nutrients: nutrients,
                   conversion_method: "weight",
                   source_used: source_used
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
          scaled_range =
            Range.from_range(
              grams_range.min / serving_size * base_per_serving,
              grams_range.best / serving_size * base_per_serving,
              grams_range.max / serving_size * base_per_serving,
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
      %Decimal{} = conf ->
        Decimal.to_float(conf)

      conf when is_float(conf) ->
        conf

      conf when is_integer(conf) ->
        conf * 1.0

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
      error: result.error,
      measurement_type: result.measurement_type,
      conversion_method: result.conversion_method,
      source_used: result.source_used,
      available_sources: result.available_sources || []
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
