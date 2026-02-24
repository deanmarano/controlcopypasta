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
    # Packed measurement reduces variation
    "packed" => 0.5,
    "loosely packed" => 0.7,
    # Sifted is more consistent
    "sifted" => 0.5,
    "firmly packed" => 0.4,
    # Chopping increases variation
    "chopped" => 1.2,
    "diced" => 1.1,
    "minced" => 1.3,
    "sliced" => 1.15
  }

  # Known count items with explicit min/max ranges (in grams per item)
  # Based on USDA data and typical grocery store ranges
  # Names should match canonical ingredient names in the database
  @count_item_ranges %{
    # Eggs
    "egg" => %{min: 44, best: 50, max: 63},
    "egg white" => %{min: 30, best: 33, max: 38},
    "egg yolk" => %{min: 14, best: 17, max: 20},

    # Citrus
    "lemon" => %{min: 58, best: 85, max: 140},
    "lime" => %{min: 44, best: 65, max: 100},
    "orange" => %{min: 96, best: 130, max: 184},

    # Common produce (names match canonical ingredients)
    "garlic" => %{min: 3, best: 4, max: 6},
    "onion" => %{min: 110, best: 150, max: 200},
    "shallot" => %{min: 20, best: 30, max: 45},
    "green onion" => %{min: 10, best: 15, max: 20},
    "potato" => %{min: 120, best: 150, max: 200},
    "sweet potato" => %{min: 100, best: 130, max: 180},
    "tomato" => %{min: 91, best: 123, max: 182},
    "cherry tomato" => %{min: 12, best: 17, max: 25},
    "apple" => %{min: 150, best: 180, max: 220},
    "banana" => %{min: 100, best: 120, max: 150},
    "avocado" => %{min: 120, best: 150, max: 200},
    "mango" => %{min: 150, best: 200, max: 280},
    "bell pepper" => %{min: 90, best: 119, max: 160},
    "red bell pepper" => %{min: 90, best: 119, max: 160},
    "green bell pepper" => %{min: 90, best: 119, max: 160},
    "yellow bell pepper" => %{min: 90, best: 119, max: 160},
    "jalapeno" => %{min: 10, best: 14, max: 20},
    "serrano chile" => %{min: 4, best: 6, max: 10},
    "habanero" => %{min: 5, best: 8, max: 12},
    "carrot" => %{min: 45, best: 60, max: 85},
    "celery" => %{min: 30, best: 40, max: 55},
    "cucumber" => %{min: 200, best: 301, max: 400},
    "zucchini" => %{min: 150, best: 196, max: 250},
    "eggplant" => %{min: 350, best: 458, max: 600},
    "broccoli" => %{min: 100, best: 148, max: 200},
    "cauliflower" => %{min: 400, best: 575, max: 750},
    "leek" => %{min: 60, best: 89, max: 120},
    "artichoke" => %{min: 90, best: 120, max: 160},
    "mushroom" => %{min: 12, best: 18, max: 25},
    "beet" => %{min: 60, best: 82, max: 110},
    "radish" => %{min: 3, best: 4.5, max: 7},
    "peach" => %{min: 120, best: 150, max: 200},
    "pear" => %{min: 140, best: 178, max: 220},
    "plum" => %{min: 50, best: 66, max: 90},
    "apricot" => %{min: 25, best: 35, max: 50},
    "dates" => %{min: 18, best: 24, max: 35},
    "figs" => %{min: 35, best: 50, max: 70},
    "olives" => %{min: 2.5, best: 3.5, max: 5},

    # Proteins
    "chicken breast" => %{min: 120, best: 174, max: 220},
    "chicken thigh" => %{min: 80, best: 116, max: 150},
    "chicken leg" => %{min: 130, best: 167, max: 210},
    "chicken wing" => %{min: 25, best: 34, max: 45},
    "salmon fillet" => %{min: 140, best: 170, max: 200},
    "bacon" => %{min: 6, best: 8, max: 12},
    "sausage" => %{min: 50, best: 68, max: 90},
    "hot dog" => %{min: 35, best: 45, max: 60},

    # Plant proteins (per block/package)
    "tofu" => %{min: 340, best: 396, max: 450},
    "tempeh" => %{min: 200, best: 227, max: 260},

    # Canned goods (per standard can)
    "canned tomatoes" => %{min: 400, best: 794, max: 800},
    "coconut milk" => %{min: 354, best: 400, max: 425},
    "coconut cream" => %{min: 354, best: 400, max: 425},

    # Dried peppers
    "red pepper flakes" => %{min: 0.3, best: 0.5, max: 1.0}
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
