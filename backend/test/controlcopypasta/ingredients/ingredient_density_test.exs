defmodule Controlcopypasta.Ingredients.IngredientDensityTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Ingredients.IngredientDensity

  defp changeset(attrs) do
    IngredientDensity.changeset(%IngredientDensity{}, Map.merge(base(), attrs))
  end

  defp base do
    %{
      canonical_ingredient_id: Ecto.UUID.generate(),
      volume_unit: "cup",
      grams_per_unit: Decimal.new("125"),
      source: "usda"
    }
  end

  describe "plausibility of grams_per_unit" do
    test "ordinary densities are accepted" do
      # flour 0.53 g/ml, sugar 0.84, honey 1.42, salt 1.22, fresh basil 0.025
      for {unit, grams} <- [
            {"cup", "125"},
            {"cup", "200"},
            {"cup", "6"},
            {"tbsp", "21"},
            {"tsp", "6"},
            {"fl oz", "30"},
            {"ml", "1"}
          ] do
        cs = changeset(%{volume_unit: unit, grams_per_unit: Decimal.new(grams)})
        assert cs.valid?, "#{grams} g per #{unit} should be accepted"
      end
    end

    test "a serving volume written into the grams column is rejected" do
      # Each of these is a real production row: the number is millilitres of a
      # standard serving, not grams per fluid ounce.
      for {label, grams} <- [{"pepsi bottle", "710"}, {"porter can", "354"}, {"wine pour", "147"}] do
        cs = changeset(%{volume_unit: "fl oz", grams_per_unit: Decimal.new(grams)})

        refute cs.valid?, "#{label} (#{grams} g per fl oz) should be rejected"
        assert errors_on(cs)[:grams_per_unit] |> Enum.join() =~ "implausibly heavy"
      end
    end

    test "an implausibly light value is rejected" do
      cs = changeset(%{volume_unit: "cup", grams_per_unit: Decimal.new("1")})

      refute cs.valid?
      assert errors_on(cs)[:grams_per_unit] |> Enum.join() =~ "implausibly light"
    end

    test "count units are not checked, having no volume" do
      # A whole watermelon weighs several kilos; "each" implies no density.
      for unit <- ["each", "whole", "can", "bunch"] do
        cs = changeset(%{volume_unit: unit, grams_per_unit: Decimal.new("4000")})
        assert cs.valid?, "#{unit} should not be density-checked"
      end
    end

    test "the existing positive-number rule still applies" do
      refute changeset(%{grams_per_unit: Decimal.new("0")}).valid?
    end
  end
end
