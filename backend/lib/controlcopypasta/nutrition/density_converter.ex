defmodule Controlcopypasta.Nutrition.DensityConverter do
  @moduledoc """
  Converts ingredient quantities to grams for nutrition calculations.

  This module handles the conversion of volume measurements (cups, tbsp, tsp) to grams
  using ingredient-specific density data. It also handles weight-to-gram conversions.

  ## Conversion Strategy

  1. If unit is already a weight unit (g, kg, oz, lb), convert directly to grams
  2. If unit is a volume unit, look up ingredient-specific density
  3. Fallback order for volume conversions:
     a. Exact density match (ingredient + unit + preparation)
     b. Base density for ingredient (no preparation)
     c. Category average density
     d. Return error if no density available

  ## Range Support

  The `to_grams_range/6` function returns a Range struct that accounts for:
  - Quantity ranges from the recipe (e.g., "5 to 6 ounces")
  - Density variations based on ingredient category
  - Preparation-based adjustments (packed vs loose, etc.)
  """

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Nutrition.{Range, DensityRanges}

  # Weight conversions to grams
  @weight_to_grams %{
    "g" => 1.0,
    "gram" => 1.0,
    "grams" => 1.0,
    "kg" => 1000.0,
    "kilogram" => 1000.0,
    "kilograms" => 1000.0,
    "oz" => 28.3495,
    "ounce" => 28.3495,
    "ounces" => 28.3495,
    "lb" => 453.592,
    "lbs" => 453.592,
    "pound" => 453.592,
    "pounds" => 453.592
  }

  # Volume unit conversions (to base unit for density lookup)
  # Maps any volume unit variant to its canonical form
  @volume_unit_canonical %{
    "cup" => "cup",
    "cups" => "cup",
    "c" => "cup",
    "tbsp" => "tbsp",
    "tablespoon" => "tbsp",
    "tablespoons" => "tbsp",
    "tsp" => "tsp",
    "teaspoon" => "tsp",
    "teaspoons" => "tsp",
    "fl oz" => "fl oz",
    "fluid oz" => "fl oz",
    "fluid ounce" => "fl oz",
    "fluid ounces" => "fl oz",
    "ml" => "ml",
    "milliliter" => "ml",
    "milliliters" => "ml",
    "l" => "liter",
    "liter" => "liter",
    "liters" => "liter",
    "quart" => "quart",
    "quarts" => "quart",
    "qt" => "quart",
    "pint" => "pint",
    "pints" => "pint",
    "pt" => "pint",
    "gallon" => "gallon",
    "gallons" => "gallon",
    "gal" => "gallon"
  }

  # Conversion ratios between volume units (relative to 1 cup = 1.0)
  @volume_to_cups %{
    "cup" => 1.0,
    "tbsp" => 1.0 / 16.0,
    "tsp" => 1.0 / 48.0,
    "fl oz" => 1.0 / 8.0,
    "ml" => 1.0 / 236.588,
    "liter" => 1000.0 / 236.588,
    "quart" => 4.0,
    "pint" => 2.0,
    "gallon" => 16.0
  }

  # Category average densities (grams per cup) as fallbacks
  # These are rough averages when ingredient-specific data isn't available
  @category_densities %{
    "grain" => 130.0,      # flour, rice, oats average
    "sweetener" => 200.0,  # sugar average
    "dairy" => 240.0,      # milk-like liquids
    "oil" => 218.0,        # oils average
    "produce" => 150.0,    # chopped vegetables average
    "spice" => 6.0,        # ground spices (per tbsp: ~2.5g, so cup: ~40g, but we store per cup)
    "herb" => 30.0,        # fresh herbs, loosely packed
    "nut" => 140.0,        # chopped nuts average
    "legume" => 180.0,     # cooked beans average
    "protein" => 140.0,    # diced meat average
    "condiment" => 250.0,  # liquid condiments average
    "other" => 150.0       # generic fallback
  }

  @doc """
  Converts a quantity to grams using ingredient-specific density.

  ## Parameters

  - `canonical_id` - The canonical ingredient ID
  - `quantity` - The numeric quantity
  - `unit` - The unit of measurement
  - `opts` - Options:
    - `:preparation` - The preparation method (e.g., "packed", "sifted")
    - `:category` - The ingredient category for fallback densities

  ## Returns

  - `{:ok, grams}` - The quantity in grams
  - `{:error, :no_density}` - No density data available
  - `{:error, :invalid_unit}` - Unit not recognized
  - `{:error, :no_quantity}` - No quantity provided

  ## Examples

      iex> to_grams(flour_id, 2, "cup")
      {:ok, 250.0}

      iex> to_grams(flour_id, 1, "cup", preparation: "packed")
      {:ok, 140.0}

      iex> to_grams(butter_id, 4, "oz")
      {:ok, 113.4}
  """
  def to_grams(canonical_id, quantity, unit, opts \\ [])

  def to_grams(_canonical_id, nil, _unit, _opts), do: {:error, :no_quantity}

  # Handle nil/count units (e.g., "3 eggs" with no unit)
  def to_grams(canonical_id, quantity, nil, opts) do
    convert_count_to_grams(canonical_id, quantity, opts)
  end

  def to_grams(canonical_id, quantity, unit, opts) do
    normalized_unit = normalize_unit(unit)

    cond do
      # Direct weight conversion
      weight_unit?(normalized_unit) ->
        convert_weight_to_grams(quantity, normalized_unit)

      # Volume unit - need density lookup
      volume_unit?(normalized_unit) ->
        convert_volume_to_grams(canonical_id, quantity, normalized_unit, opts)

      # Count units (each, whole, etc.)
      count_unit?(normalized_unit) ->
        convert_count_to_grams(canonical_id, quantity, opts)

      # Unknown unit
      true ->
        {:error, :invalid_unit}
    end
  end

  @doc """
  Converts a quantity range to a grams range, accounting for density variation.

  This function combines:
  - Quantity ranges from the recipe (qty_min to qty_max)
  - Density variations based on ingredient category and preparation

  ## Parameters

  - `canonical_id` - The canonical ingredient ID
  - `qty` - The best quantity estimate
  - `qty_min` - Minimum quantity (from recipe range like "5 to 6")
  - `qty_max` - Maximum quantity
  - `unit` - The unit of measurement
  - `opts` - Options:
    - `:preparation` - The preparation method
    - `:category` - The ingredient category

  ## Returns

  - `{:ok, Range.t()}` - A range with min/best/max grams
  - `{:error, reason}` - If conversion fails

  ## Examples

      iex> to_grams_range(salmon_id, 5.5, 5.0, 6.0, "oz", category: "seafood")
      {:ok, %Range{min: 140.0, best: 156.0, max: 170.0, confidence: 1.0}}
  """
  def to_grams_range(canonical_id, qty, qty_min, qty_max, unit, opts \\ [])

  def to_grams_range(_canonical_id, nil, _qty_min, _qty_max, _unit, _opts), do: {:error, :no_quantity}

  # Handle nil/count units (e.g., "3 eggs" with no unit)
  def to_grams_range(canonical_id, qty, qty_min, qty_max, nil, opts) do
    convert_count_to_grams_range(canonical_id, qty, qty_min, qty_max, opts)
  end

  def to_grams_range(canonical_id, qty, qty_min, qty_max, unit, opts) do
    normalized_unit = normalize_unit(unit)
    # Default min/max to qty if not specified
    qty_min = qty_min || qty
    qty_max = qty_max || qty

    cond do
      # Direct weight conversion - very low variation
      weight_unit?(normalized_unit) ->
        convert_weight_to_grams_range(qty, qty_min, qty_max, normalized_unit)

      # Volume unit - apply category-based density variation
      volume_unit?(normalized_unit) ->
        convert_volume_to_grams_range(canonical_id, qty, qty_min, qty_max, normalized_unit, opts)

      # Count units (each, whole, etc.)
      count_unit?(normalized_unit) ->
        convert_count_to_grams_range(canonical_id, qty, qty_min, qty_max, opts)

      # Unknown unit
      true ->
        {:error, :invalid_unit}
    end
  end

  # Weight conversion with range - weights have minimal variation
  defp convert_weight_to_grams_range(qty, qty_min, qty_max, unit) do
    case Map.get(@weight_to_grams, unit) do
      nil ->
        {:error, :invalid_unit}

      factor ->
        range = Range.from_range(
          to_float(qty_min) * factor,
          to_float(qty) * factor,
          to_float(qty_max) * factor
        )
        {:ok, range}
    end
  end

  # Volume conversion with range - applies density variation
  defp convert_volume_to_grams_range(canonical_id, qty, qty_min, qty_max, unit, opts) do
    preparation = Keyword.get(opts, :preparation)
    category = Keyword.get(opts, :category)

    canonical_volume_unit = Map.get(@volume_unit_canonical, unit)

    # Try to get density from database
    case get_density_grams_per_unit(canonical_id, canonical_volume_unit, preparation) do
      {:ok, grams_per_unit} ->
        # Get density range with category variation
        density_range = DensityRanges.density_to_range(grams_per_unit, category, preparation)

        # Convert quantity range to base unit
        qty_min_base = convert_volume_quantity(qty_min, unit, canonical_volume_unit)
        qty_base = convert_volume_quantity(qty, unit, canonical_volume_unit)
        qty_max_base = convert_volume_quantity(qty_max, unit, canonical_volume_unit)

        # Create quantity range
        qty_range = Range.from_range(qty_min_base, qty_base, qty_max_base)

        # Multiply quantity range by density range
        grams_range = Range.multiply_ranges(qty_range, density_range)

        {:ok, grams_range}

      {:error, :not_found} ->
        # Try to derive from cup density
        derive_from_cup_density_range(canonical_id, qty, qty_min, qty_max, unit, canonical_volume_unit, category)
    end
  end

  defp derive_from_cup_density_range(canonical_id, qty, qty_min, qty_max, _unit, canonical_volume_unit, category) do
    # If we don't have the exact unit, try to find cup density and derive
    case Ingredients.get_any_density(canonical_id, "cup") do
      {:ok, cup_density} ->
        grams_per_cup = Decimal.to_float(cup_density.grams_per_unit)
        density_range = DensityRanges.density_to_range(grams_per_cup, category, nil)

        # Convert quantity to cups
        qty_min_cups = convert_to_cups(qty_min, canonical_volume_unit)
        qty_cups = convert_to_cups(qty, canonical_volume_unit)
        qty_max_cups = convert_to_cups(qty_max, canonical_volume_unit)

        qty_range = Range.from_range(qty_min_cups, qty_cups, qty_max_cups)
        grams_range = Range.multiply_ranges(qty_range, density_range)

        {:ok, grams_range}

      {:error, :not_found} ->
        # Fall back to category average
        if category do
          grams_per_cup = category_density(category)
          density_range = DensityRanges.density_to_range(grams_per_cup, category, nil)

          qty_min_cups = convert_to_cups(qty_min, canonical_volume_unit)
          qty_cups = convert_to_cups(qty, canonical_volume_unit)
          qty_max_cups = convert_to_cups(qty_max, canonical_volume_unit)

          qty_range = Range.from_range(qty_min_cups, qty_cups, qty_max_cups)
          grams_range = Range.multiply_ranges(qty_range, density_range)

          {:ok, grams_range}
        else
          {:error, :no_density}
        end
    end
  end

  # Count-based conversion with range
  defp convert_count_to_grams_range(canonical_id, qty, qty_min, qty_max, opts) do
    category = Keyword.get(opts, :category)
    canonical_name = Keyword.get(opts, :canonical_name)

    # Try "each" first, then "whole"
    case Ingredients.get_density(canonical_id, "each", nil) do
      {:ok, density} ->
        grams_per_item = Decimal.to_float(density.grams_per_unit)

        # Try to get explicit count item range, or use density with category variation
        density_range =
          if canonical_name do
            DensityRanges.count_item_range_or_fallback(canonical_name, grams_per_item, category)
          else
            DensityRanges.density_to_range(grams_per_item, category, nil)
          end

        qty_range = Range.from_range(to_float(qty_min), to_float(qty), to_float(qty_max))
        grams_range = Range.multiply_ranges(qty_range, density_range)

        {:ok, grams_range}

      {:error, :not_found} ->
        case Ingredients.get_density(canonical_id, "whole", nil) do
          {:ok, density} ->
            grams_per_item = Decimal.to_float(density.grams_per_unit)

            density_range =
              if canonical_name do
                DensityRanges.count_item_range_or_fallback(canonical_name, grams_per_item, category)
              else
                DensityRanges.density_to_range(grams_per_item, category, nil)
              end

            qty_range = Range.from_range(to_float(qty_min), to_float(qty), to_float(qty_max))
            grams_range = Range.multiply_ranges(qty_range, density_range)

            {:ok, grams_range}

          {:error, :not_found} ->
            {:error, :no_count_density}
        end
    end
  end

  @doc """
  Batch converts multiple ingredients to grams.

  Takes a list of ingredient maps with keys:
  - `:canonical_id`
  - `:quantity`
  - `:unit`
  - `:preparation` (optional)
  - `:category` (optional)

  Returns a list of results in the same order.
  """
  def batch_to_grams(ingredients) when is_list(ingredients) do
    Enum.map(ingredients, fn ing ->
      result = to_grams(
        ing[:canonical_id],
        ing[:quantity],
        ing[:unit],
        preparation: ing[:preparation],
        category: ing[:category]
      )

      Map.put(ing, :grams_result, result)
    end)
  end

  @doc """
  Checks if a unit is a weight unit.
  """
  def weight_unit?(unit) when is_binary(unit) do
    Map.has_key?(@weight_to_grams, String.downcase(unit))
  end

  def weight_unit?(_), do: false

  @doc """
  Checks if a unit is a volume unit.
  """
  def volume_unit?(unit) when is_binary(unit) do
    Map.has_key?(@volume_unit_canonical, String.downcase(unit))
  end

  def volume_unit?(_), do: false

  # Count units for countable items (eggs, lemons, garlic cloves, tofu blocks, etc.)
  @count_units ~w(each whole piece pieces item items unit units count
                  clove cloves head heads block blocks
                  stalk stalks sprig sprigs bunch bunches
                  slice slices can cans)

  @doc """
  Checks if a unit is a count unit (for countable items like eggs).
  """
  def count_unit?(unit) when is_binary(unit) do
    String.downcase(unit) in @count_units
  end

  def count_unit?(_), do: false

  @doc """
  Returns the category average density in grams per cup.
  """
  def category_density(category) when is_binary(category) do
    Map.get(@category_densities, category, @category_densities["other"])
  end

  def category_density(_), do: @category_densities["other"]

  # Private functions

  defp normalize_unit(unit) when is_binary(unit), do: String.downcase(String.trim(unit))
  defp normalize_unit(_), do: nil

  defp convert_weight_to_grams(quantity, unit) do
    case Map.get(@weight_to_grams, unit) do
      nil -> {:error, :invalid_unit}
      factor -> {:ok, to_float(quantity) * factor}
    end
  end

  defp convert_volume_to_grams(canonical_id, quantity, unit, opts) do
    preparation = Keyword.get(opts, :preparation)
    category = Keyword.get(opts, :category)

    canonical_volume_unit = Map.get(@volume_unit_canonical, unit)

    # Try to get density from database
    case get_density_grams_per_unit(canonical_id, canonical_volume_unit, preparation) do
      {:ok, grams_per_unit} ->
        # Convert quantity to the density's base unit and multiply
        quantity_in_base = convert_volume_quantity(quantity, unit, canonical_volume_unit)
        {:ok, quantity_in_base * grams_per_unit}

      {:error, :not_found} ->
        # Try to derive from cup density
        derive_from_cup_density(canonical_id, quantity, unit, canonical_volume_unit, category)
    end
  end

  defp get_density_grams_per_unit(canonical_id, volume_unit, preparation) do
    case Ingredients.get_density(canonical_id, volume_unit, preparation) do
      {:ok, density} ->
        {:ok, Decimal.to_float(density.grams_per_unit)}

      {:error, :not_found} when not is_nil(preparation) ->
        # Try without preparation
        case Ingredients.get_density(canonical_id, volume_unit, nil) do
          {:ok, density} -> {:ok, Decimal.to_float(density.grams_per_unit)}
          error -> error
        end

      error ->
        error
    end
  end

  defp derive_from_cup_density(canonical_id, quantity, _unit, canonical_volume_unit, category) do
    # If we don't have the exact unit, try to find cup density and derive
    case Ingredients.get_any_density(canonical_id, "cup") do
      {:ok, cup_density} ->
        grams_per_cup = Decimal.to_float(cup_density.grams_per_unit)
        # Convert quantity to cups, then multiply by grams per cup
        quantity_in_cups = convert_to_cups(quantity, canonical_volume_unit)
        {:ok, quantity_in_cups * grams_per_cup}

      {:error, :not_found} ->
        # Fall back to category average
        if category do
          grams_per_cup = category_density(category)
          quantity_in_cups = convert_to_cups(quantity, canonical_volume_unit)
          {:ok, quantity_in_cups * grams_per_cup}
        else
          {:error, :no_density}
        end
    end
  end

  # Convert count-based items (eggs, lemons, etc.) to grams
  # Looks up density with volume_unit "each" or "whole"
  defp convert_count_to_grams(canonical_id, quantity, _opts) do
    # Try "each" first, then "whole"
    case Ingredients.get_density(canonical_id, "each", nil) do
      {:ok, density} ->
        {:ok, to_float(quantity) * Decimal.to_float(density.grams_per_unit)}

      {:error, :not_found} ->
        case Ingredients.get_density(canonical_id, "whole", nil) do
          {:ok, density} ->
            {:ok, to_float(quantity) * Decimal.to_float(density.grams_per_unit)}

          {:error, :not_found} ->
            {:error, :no_count_density}
        end
    end
  end

  defp convert_volume_quantity(quantity, from_unit, to_unit) when from_unit == to_unit do
    to_float(quantity)
  end

  defp convert_volume_quantity(quantity, from_unit, to_unit) do
    from_cups = Map.get(@volume_to_cups, from_unit, 1.0)
    to_cups = Map.get(@volume_to_cups, to_unit, 1.0)
    to_float(quantity) * from_cups / to_cups
  end

  defp convert_to_cups(quantity, unit) do
    cups_ratio = Map.get(@volume_to_cups, unit, 1.0)
    to_float(quantity) * cups_ratio
  end

  defp to_float(value) when is_float(value), do: value
  defp to_float(value) when is_integer(value), do: value * 1.0
  defp to_float(%Decimal{} = value), do: Decimal.to_float(value)
  defp to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {f, _} -> f
      :error -> 0.0
    end
  end
  defp to_float(_), do: 0.0
end
