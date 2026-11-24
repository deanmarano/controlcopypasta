defmodule Controlcopypasta.Nutrition.PinchConversionTest do
  use Controlcopypasta.DataCase

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Nutrition.DensityConverter

  # A pinch was filed with the count units because salt has a curated
  # grams-per-pinch record. Nothing else did, so every other correctly parsed
  # "Pinch of X" failed with :no_count_density -- 4,524 stored rows of it.
  #
  # A pinch is really a very small volume (1/16 tsp; a dash is 1/8), so the
  # count lookup now falls back to that equivalence. The fallback order matters:
  # a curated per-ingredient record still wins.

  setup do
    {:ok, cinnamon} =
      Ingredients.create_canonical_ingredient(%{
        name: "test cinnamon",
        display_name: "Test Cinnamon",
        category: "spice"
      })

    # 1 tsp of ground cinnamon weighs about 2.6 g.
    {:ok, _} =
      Ingredients.create_density(%{
        canonical_ingredient_id: cinnamon.id,
        volume_unit: "tsp",
        grams_per_unit: Decimal.new("2.6"),
        source: "usda"
      })

    {:ok, salt} =
      Ingredients.create_canonical_ingredient(%{
        name: "test curated salt",
        display_name: "Test Curated Salt",
        category: "spice"
      })

    # A deliberately odd number, so a test cannot pass by coincidence if the
    # volume fallback were used instead of this record.
    {:ok, _} =
      Ingredients.create_density(%{
        canonical_ingredient_id: salt.id,
        volume_unit: "pinch",
        grams_per_unit: Decimal.new("0.77"),
        source: "manual"
      })

    {:ok, nothing} =
      Ingredients.create_canonical_ingredient(%{
        name: "test undocumented herb",
        display_name: "Test Undocumented Herb",
        category: "herb"
      })

    %{cinnamon: cinnamon, salt: salt, nothing: nothing}
  end

  describe "pinch as a small volume" do
    test "an ingredient with only a volume density converts", %{cinnamon: cinnamon} do
      {:ok, grams} = DensityConverter.to_grams(cinnamon.id, 1, "pinch")

      # 1/16 tsp x 2.6 g/tsp
      assert_in_delta grams, 2.6 / 16, 0.001
    end

    test "a dash is twice a pinch", %{cinnamon: cinnamon} do
      {:ok, pinch} = DensityConverter.to_grams(cinnamon.id, 1, "pinch")
      {:ok, dash} = DensityConverter.to_grams(cinnamon.id, 1, "dash")

      assert_in_delta dash, pinch * 2, 0.001
    end

    test "plurals and quantities scale", %{cinnamon: cinnamon} do
      {:ok, one} = DensityConverter.to_grams(cinnamon.id, 1, "pinch")
      {:ok, three} = DensityConverter.to_grams(cinnamon.id, 3, "pinches")

      assert_in_delta three, one * 3, 0.001
    end

    test "a curated per-ingredient record still wins over the equivalence",
         %{salt: salt} do
      # This is why the fallback is a fallback. The volume route would give a
      # different number; the hand-entered one is more authoritative.
      assert {:ok, 0.77} = DensityConverter.to_grams(salt.id, 1, "pinch")
    end

    test "an ingredient with no density at all still fails honestly",
         %{nothing: nothing} do
      # The fallback supplies a conversion, not a density. With nothing to
      # convert from, the answer is still "we do not know".
      assert {:error, _} = DensityConverter.to_grams(nothing.id, 1, "pinch")
    end
  end

  describe "ranges" do
    test "the range path gets the same fallback", %{cinnamon: cinnamon} do
      {:ok, range} = DensityConverter.to_grams_range(cinnamon.id, 1, 1, 2, "pinch")

      assert_in_delta range.best, 2.6 / 16, 0.01
      assert range.max > range.best
    end

    test "the range path also prefers a curated record", %{salt: salt} do
      {:ok, range} = DensityConverter.to_grams_range(salt.id, 1, 1, 1, "pinch")

      assert_in_delta range.best, 0.77, 0.001
    end
  end
end
