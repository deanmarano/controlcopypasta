defmodule Controlcopypasta.Ingredients.DensitySelectionTest do
  use Controlcopypasta.DataCase

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.CanonicalIngredient
  alias Controlcopypasta.Repo

  # The production catalog holds 342 (ingredient, unit, preparation) groups with
  # more than one density row, and the values disagree in 214 of them. These
  # rows reproduce that: one trusted, one not, for the same cup measure.
  setup do
    ingredient =
      %CanonicalIngredient{}
      |> CanonicalIngredient.changeset(%{
        name: "density-selection-fixture",
        display_name: "Density Selection Fixture"
      })
      |> Repo.insert!()

    for {source, grams} <- [{"fatsecret", "40.0"}, {"usda", "255.0"}, {"openfoodfacts", "90.0"}] do
      {:ok, _} =
        Ingredients.create_density(%{
          canonical_ingredient_id: ingredient.id,
          volume_unit: "cup",
          grams_per_unit: Decimal.new(grams),
          source: source
        })
    end

    %{ingredient: ingredient}
  end

  test "the most trusted source wins a contested unit", %{ingredient: ingredient} do
    {:ok, density} = Ingredients.get_density(ingredient.id, "cup")

    assert density.source == "usda"
    assert Decimal.equal?(density.grams_per_unit, Decimal.new("255.0"))
  end

  test "get_any_density/2 applies the same order", %{ingredient: ingredient} do
    {:ok, density} = Ingredients.get_any_density(ingredient.id, "cup")
    assert density.source == "usda"
  end

  test "selection is stable when row order changes", %{ingredient: ingredient} do
    {:ok, first} = Ingredients.get_density(ingredient.id, "cup")

    # Rewriting the rows changes their physical order, which is what an
    # unordered `limit: 1` was sensitive to.
    Repo.update_all(Controlcopypasta.Ingredients.IngredientDensity,
      set: [updated_at: DateTime.utc_now()]
    )

    {:ok, again} = Ingredients.get_density(ingredient.id, "cup")
    assert again.id == first.id
  end
end
