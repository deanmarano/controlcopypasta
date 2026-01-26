defmodule Controlcopypasta.Nutrition.DensityRangesTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Nutrition.DensityRanges

  describe "category_variation/1" do
    test "returns correct variation for known categories" do
      assert DensityRanges.category_variation("grain") == 0.15
      assert DensityRanges.category_variation("oil") == 0.02
      assert DensityRanges.category_variation("herb") == 0.30
    end

    test "returns default variation for unknown category" do
      assert DensityRanges.category_variation("unknown") == 0.15
    end

    test "handles nil category" do
      assert DensityRanges.category_variation(nil) == 0.15
    end
  end

  describe "preparation_modifier/1" do
    test "returns correct modifier for known preparations" do
      assert DensityRanges.preparation_modifier("packed") == 0.5
      assert DensityRanges.preparation_modifier("chopped") == 1.2
      assert DensityRanges.preparation_modifier("sifted") == 0.5
    end

    test "returns 1.0 for unknown preparation" do
      assert DensityRanges.preparation_modifier("unknown") == 1.0
    end

    test "handles nil preparation" do
      assert DensityRanges.preparation_modifier(nil) == 1.0
    end
  end

  describe "density_to_range/3" do
    test "creates a range with category variation" do
      range = DensityRanges.density_to_range(125.0, "grain", nil)

      # 15% variation
      assert range.min == 106.25
      assert range.best == 125.0
      assert range.max == 143.75
    end

    test "applies preparation modifier to variation" do
      # Packed reduces variation by 50%
      range = DensityRanges.density_to_range(125.0, "grain", "packed")

      # 15% * 0.5 = 7.5% variation
      assert range.min == 115.625
      assert range.best == 125.0
      assert range.max == 134.375
    end

    test "oils have very low variation" do
      range = DensityRanges.density_to_range(218.0, "oil", nil)

      # 2% variation
      assert_in_delta range.min, 213.64, 0.01
      assert range.best == 218.0
      assert_in_delta range.max, 222.36, 0.01
    end
  end

  describe "count_item_range/1" do
    test "returns known range for egg" do
      {:ok, range} = DensityRanges.count_item_range("egg")

      assert range.min == 44.0
      assert range.best == 50.0
      assert range.max == 63.0
    end

    test "returns known range for salmon fillet" do
      {:ok, range} = DensityRanges.count_item_range("salmon fillet")

      assert range.min == 140.0
      assert range.best == 170.0
      assert range.max == 200.0
    end

    test "returns error for unknown item" do
      assert {:error, :not_found} = DensityRanges.count_item_range("unknown item")
    end

    test "is case insensitive" do
      {:ok, range1} = DensityRanges.count_item_range("egg")
      {:ok, range2} = DensityRanges.count_item_range("EGG")

      assert range1 == range2
    end
  end

  describe "count_item_range_or_fallback/3" do
    test "returns known range when available" do
      range = DensityRanges.count_item_range_or_fallback("egg", 50, "protein")

      assert range.min == 44.0
      assert range.best == 50.0
      assert range.max == 63.0
    end

    test "falls back to density with category variation for unknown items" do
      range = DensityRanges.count_item_range_or_fallback("unknown", 100, "other")

      # 15% default variation
      assert_in_delta range.min, 85.0, 0.001
      assert range.best == 100.0
      assert_in_delta range.max, 115.0, 0.001
    end
  end

  describe "all_count_items/0" do
    test "returns a map of all known count items" do
      items = DensityRanges.all_count_items()

      assert is_map(items)
      assert Map.has_key?(items, "egg")
      assert Map.has_key?(items, "lemon")
      assert Map.has_key?(items, "salmon fillet")
    end
  end

  describe "all_categories/0" do
    test "returns a map of all category variations" do
      categories = DensityRanges.all_categories()

      assert is_map(categories)
      assert Map.has_key?(categories, "grain")
      assert Map.has_key?(categories, "oil")
      assert Map.has_key?(categories, "herb")
    end
  end
end
