defmodule Controlcopypasta.ShoppingLists.QuantityCombinerTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.ShoppingLists.QuantityCombiner

  describe "combine/4" do
    test "adds quantities with same unit" do
      {:ok, {qty, unit}} =
        QuantityCombiner.combine(
          Decimal.new("2"),
          "cup",
          Decimal.new("1"),
          "cup"
        )

      assert Decimal.equal?(qty, Decimal.new("3"))
      assert unit == "cup"
    end

    test "converts and adds compatible volume units" do
      # 1 cup + 4 tbsp = 1.25 cups (approximately, since 1 cup = 16 tbsp)
      {:ok, {qty, unit}} =
        QuantityCombiner.combine(
          Decimal.new("1"),
          "cup",
          Decimal.new("4"),
          "tbsp"
        )

      # 1 cup (236.588ml) + 4 tbsp (59.148ml) = 295.736ml = ~1.25 cups
      assert unit == "cup"
      assert Decimal.to_float(qty) > 1.0
      assert Decimal.to_float(qty) < 1.5
    end

    test "converts and adds compatible weight units" do
      # 1 lb + 8 oz = 1.5 lbs
      {:ok, {qty, unit}} =
        QuantityCombiner.combine(
          Decimal.new("1"),
          "lb",
          Decimal.new("8"),
          "oz"
        )

      assert unit == "lb"
      assert Decimal.equal?(qty, Decimal.new("1.5"))
    end

    test "returns incompatible for volume and weight" do
      assert {:incompatible, _reason} =
               QuantityCombiner.combine(
                 Decimal.new("1"),
                 "cup",
                 Decimal.new("1"),
                 "lb"
               )
    end

    test "handles case-insensitive units" do
      {:ok, {qty, _unit}} =
        QuantityCombiner.combine(
          Decimal.new("1"),
          "Cup",
          Decimal.new("1"),
          "CUP"
        )

      assert Decimal.equal?(qty, Decimal.new("2"))
    end
  end

  describe "can_combine?/2" do
    test "returns true for matching canonical_ingredient_id" do
      id = Ecto.UUID.generate()

      assert QuantityCombiner.can_combine?(
               %{canonical_ingredient_id: id, canonical_name: nil, raw_name: nil},
               %{canonical_ingredient_id: id, canonical_name: nil, raw_name: nil}
             )
    end

    test "returns true for matching canonical_name" do
      assert QuantityCombiner.can_combine?(
               %{canonical_ingredient_id: nil, canonical_name: "flour", raw_name: nil},
               %{canonical_ingredient_id: nil, canonical_name: "Flour", raw_name: nil}
             )
    end

    test "returns true for similar raw_name (contains)" do
      assert QuantityCombiner.can_combine?(
               %{canonical_ingredient_id: nil, canonical_name: nil, raw_name: "chicken breast"},
               %{canonical_ingredient_id: nil, canonical_name: nil, raw_name: "chicken"}
             )
    end

    test "returns true for pluralization differences" do
      assert QuantityCombiner.can_combine?(
               %{canonical_ingredient_id: nil, canonical_name: nil, raw_name: "egg"},
               %{canonical_ingredient_id: nil, canonical_name: nil, raw_name: "eggs"}
             )
    end

    test "returns false for different items" do
      refute QuantityCombiner.can_combine?(
               %{canonical_ingredient_id: nil, canonical_name: nil, raw_name: "flour"},
               %{canonical_ingredient_id: nil, canonical_name: nil, raw_name: "sugar"}
             )
    end
  end

  describe "merge_items/2" do
    test "merges items with compatible units" do
      existing = %{
        quantity: Decimal.new("2"),
        unit: "cup",
        canonical_name: "flour",
        raw_name: "flour",
        source_recipe_ids: ["recipe1"]
      }

      new_attrs = %{
        quantity: Decimal.new("1"),
        unit: "cup",
        canonical_name: "flour",
        raw_name: "flour",
        source_recipe_ids: ["recipe2"]
      }

      {:ok, merged} = QuantityCombiner.merge_items(existing, new_attrs)

      assert Decimal.equal?(merged.quantity, Decimal.new("3"))
      assert merged.unit == "cup"
      assert "recipe1" in merged.source_recipe_ids
      assert "recipe2" in merged.source_recipe_ids
    end

    test "returns incompatible when quantity is nil" do
      existing = %{quantity: nil, unit: "cup", source_recipe_ids: []}
      new_attrs = %{quantity: Decimal.new("1"), unit: "cup", source_recipe_ids: []}

      assert {:incompatible, _} = QuantityCombiner.merge_items(existing, new_attrs)
    end

    test "returns incompatible when unit is nil" do
      existing = %{quantity: Decimal.new("1"), unit: nil, source_recipe_ids: []}
      new_attrs = %{quantity: Decimal.new("1"), unit: "cup", source_recipe_ids: []}

      assert {:incompatible, _} = QuantityCombiner.merge_items(existing, new_attrs)
    end
  end

  describe "small units that add up" do
    test "tablespoons step up to cups once there are enough of them" do
      assert {:ok, {qty, "cup"}} =
               QuantityCombiner.combine(Decimal.new("6"), "tbsp", Decimal.new("7"), "tbsp")

      assert Decimal.equal?(qty, Decimal.new("0.8125"))
    end

    test "a few tablespoons stay tablespoons" do
      assert {:ok, {qty, "tbsp"}} =
               QuantityCombiner.combine(Decimal.new("1"), "tbsp", Decimal.new("2"), "tbsp")

      assert Decimal.equal?(qty, Decimal.new("3"))
    end

    test "teaspoons step up to tablespoons" do
      assert {:ok, {qty, "tbsp"}} =
               QuantityCombiner.combine(Decimal.new("2"), "tsp", Decimal.new("4"), "tsp")

      assert Decimal.equal?(qty, Decimal.new("2"))
    end
  end

  describe "merging plain counts" do
    test "adds two unitless quantities of the same thing" do
      existing = %{
        quantity: Decimal.new("2"),
        unit: nil,
        canonical_name: "avocado",
        raw_name: "avocado",
        source_recipe_ids: ["a"]
      }

      new_attrs = %{quantity: Decimal.new("3"), unit: nil, source_recipe_ids: ["b"]}

      assert {:ok, merged} = QuantityCombiner.merge_items(existing, new_attrs)
      assert Decimal.equal?(merged.quantity, Decimal.new("5"))
      assert merged.unit == nil
      assert merged.display_text == "5 avocado"
      assert merged.source_recipe_ids == ["a", "b"]
    end

    test "writes a merged measure with fractions" do
      existing = %{
        quantity: Decimal.new("0.25"),
        unit: "cup",
        canonical_name: "water",
        raw_name: "water",
        source_recipe_ids: []
      }

      new_attrs = %{quantity: Decimal.new("0.25"), unit: "cup", source_recipe_ids: []}

      assert {:ok, merged} = QuantityCombiner.merge_items(existing, new_attrs)
      assert merged.display_text == "½ cup water"
    end
  end
end
