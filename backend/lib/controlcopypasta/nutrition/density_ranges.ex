defmodule Controlcopypasta.Nutrition.DensityRanges do
  @moduledoc """
  Provides density variation data for nutrition uncertainty calculations.

  Different ingredient categories have varying levels of natural variation:
  - Liquids (oils, dairy) are very consistent
  - Produce and herbs vary significantly based on chopping, packing, etc.
  - Grains vary based on whether sifted, packed, or loosely measured

  This module also provides explicit ranges for count-based items
  like eggs, lemons, etc. where size can vary significantly.
  """

  alias Controlcopypasta.Nutrition.Range

  # Category-based variation percentages
  # These represent the typical spread from a "standard" measurement
  @category_variation %{
    # Liquids - very consistent
    "oil" => 0.02,
    "dairy" => 0.05,
    "condiment" => 0.08,

    # Grains and starches - moderate variation
    "grain" => 0.15,
    "sweetener" => 0.10,
    "legume" => 0.12,

    # Produce and herbs - higher variation
    "produce" => 0.20,
    "herb" => 0.30,
    "nut" => 0.15,

    # Proteins - moderate to high variation
    "protein" => 0.15,
    "seafood" => 0.18,

    # Spices - consistent when measured
    "spice" => 0.08,

    # Default for unknown categories
    "other" => 0.15
  }

  # Preparation-based modifiers
  # Some preparations reduce or increase variation
  @preparation_modifiers %{
    "packed" => 0.5,        # Packed measurement reduces variation
    "loosely packed" => 0.7,
    "sifted" => 0.5,        # Sifted is more consistent
    "firmly packed" => 0.4,
    "chopped" => 1.2,       # Chopping increases variation
    "diced" => 1.1,
    "minced" => 1.3,
    "sliced" => 1.15
  }

  # Known count items with explicit min/max ranges (in grams per item)
  # Based on USDA data and typical grocery store ranges
  @count_item_ranges %{
    # Eggs
    "egg" => %{min: 44, best: 50, max: 63},             # Small to large
    "egg white" => %{min: 30, best: 33, max: 38},
    "egg yolk" => %{min: 14, best: 17, max: 20},

    # Citrus
    "lemon" => %{min: 58, best: 84, max: 140},
    "lime" => %{min: 44, best: 67, max: 100},
    "orange" => %{min: 96, best: 131, max: 184},

    # Common produce
    "garlic clove" => %{min: 3, best: 4, max: 6},
    "onion" => %{min: 110, best: 150, max: 200},        # Medium onion
    "potato" => %{min: 150, best: 213, max: 300},       # Medium potato
    "tomato" => %{min: 91, best: 123, max: 182},        # Medium tomato
    "apple" => %{min: 150, best: 182, max: 220},
    "banana" => %{min: 100, best: 118, max: 150},
    "avocado" => %{min: 136, best: 170, max: 230},
    "bell pepper" => %{min: 120, best: 165, max: 200},
    "carrot" => %{min: 50, best: 72, max: 100},
    "celery stalk" => %{min: 35, best: 45, max: 55},

    # Proteins
    "chicken breast" => %{min: 120, best: 174, max: 220},
    "chicken thigh" => %{min: 80, best: 116, max: 150},
    "salmon fillet" => %{min: 140, best: 170, max: 200},

    # Bread and baked
    "bread slice" => %{min: 25, best: 32, max: 45}
  }

  @doc """
  Returns the variation percentage for a category.

  ## Examples

      iex> DensityRanges.category_variation("grain")
      0.15

      iex> DensityRanges.category_variation("oil")
      0.02
  """
  @spec category_variation(String.t() | nil) :: float()
  def category_variation(nil), do: @category_variation["other"]

  def category_variation(category) when is_binary(category) do
    Map.get(@category_variation, category, @category_variation["other"])
  end

  @doc """
  Returns the preparation modifier for adjusting variation.

  A value < 1.0 means the preparation reduces variation.
  A value > 1.0 means the preparation increases variation.

  ## Examples

      iex> DensityRanges.preparation_modifier("packed")
      0.5

      iex> DensityRanges.preparation_modifier("chopped")
      1.2
  """
  @spec preparation_modifier(String.t() | nil) :: float()
  def preparation_modifier(nil), do: 1.0

  def preparation_modifier(prep) when is_binary(prep) do
    Map.get(@preparation_modifiers, String.downcase(prep), 1.0)
  end

  @doc """
  Converts a density value to a Range with category-appropriate variation.

  ## Parameters

  - `grams_per_unit` - The base density (grams per unit)
  - `category` - The ingredient category
  - `preparation` - Optional preparation method

  ## Returns

  A Range struct with min/best/max values.

  ## Examples

      iex> DensityRanges.density_to_range(125.0, "grain", nil)
      %Range{min: 106.25, best: 125.0, max: 143.75, confidence: 1.0}
  """
  @spec density_to_range(number(), String.t() | nil, String.t() | nil) :: Range.t()
  def density_to_range(grams_per_unit, category, preparation) do
    base_variation = category_variation(category)
    prep_modifier = preparation_modifier(preparation)
    variation = base_variation * prep_modifier

    Range.from_value_with_variation(grams_per_unit, variation)
  end

  @doc """
  Returns the weight range for a count item.

  Returns `{:ok, Range.t()}` if the item is known,
  or `{:error, :not_found}` if unknown.

  ## Examples

      iex> DensityRanges.count_item_range("egg")
      {:ok, %Range{min: 44.0, best: 50.0, max: 63.0, confidence: 1.0}}

      iex> DensityRanges.count_item_range("unknown item")
      {:error, :not_found}
  """
  @spec count_item_range(String.t()) :: {:ok, Range.t()} | {:error, :not_found}
  def count_item_range(item_name) when is_binary(item_name) do
    normalized = String.downcase(item_name)

    case Map.get(@count_item_ranges, normalized) do
      nil -> {:error, :not_found}
      %{min: min, best: best, max: max} -> {:ok, Range.from_range(min, best, max)}
    end
  end

  @doc """
  Returns the weight range for a count item, falling back to
  a provided density value with category variation.

  ## Parameters

  - `item_name` - The name of the count item
  - `fallback_grams` - Grams per item if no explicit range is known
  - `category` - Category for calculating variation on fallback

  ## Examples

      iex> DensityRanges.count_item_range_or_fallback("egg", 50, "protein")
      %Range{min: 44.0, best: 50.0, max: 63.0, confidence: 1.0}

      iex> DensityRanges.count_item_range_or_fallback("unknown", 100, "other")
      %Range{min: 85.0, best: 100.0, max: 115.0, confidence: 1.0}
  """
  @spec count_item_range_or_fallback(String.t(), number(), String.t() | nil) :: Range.t()
  def count_item_range_or_fallback(item_name, fallback_grams, category) do
    case count_item_range(item_name) do
      {:ok, range} -> range
      {:error, :not_found} -> density_to_range(fallback_grams, category, nil)
    end
  end

  @doc """
  Lists all known count items with their ranges.
  """
  @spec all_count_items() :: map()
  def all_count_items, do: @count_item_ranges

  @doc """
  Lists all category variation percentages.
  """
  @spec all_categories() :: map()
  def all_categories, do: @category_variation
end
