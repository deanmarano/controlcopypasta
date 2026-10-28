defmodule Controlcopypasta.Ingredients.Detection.EquipmentDetectorTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.CanonicalIngredient
  alias Controlcopypasta.Ingredients.Detection.EquipmentDetector
  alias Controlcopypasta.Repo

  # Foods whose names end in a word the equipment heuristics treat as a tool.
  # Before the catalog took precedence, each of these was silently dropped
  # before matching ever ran.
  @collision_foods [
    "cooking spray",
    "nonstick cooking spray",
    "pan spray",
    "string beans",
    "lasagna sheets",
    "phyllo sheets",
    "veggie platter"
  ]

  @genuine_equipment [
    "A deep-fry thermometer",
    "An instant-read thermometer",
    "Special Equipment: a mandoline",
    "cheesecloth",
    "offset spatula",
    "Two 8-inch cake pans"
  ]

  defp canonical!(name) do
    %CanonicalIngredient{}
    |> CanonicalIngredient.changeset(%{name: name, display_name: name})
    |> Repo.insert!()
  end

  describe "is_equipment?/2 with the canonical catalog" do
    setup do
      Enum.each(@collision_foods, &canonical!/1)
      %{lookup: Ingredients.build_ingredient_lookup()}
    end

    test "no canonical ingredient or alias is classified as equipment", %{lookup: lookup} do
      names =
        CanonicalIngredient
        |> Repo.all()
        |> Enum.flat_map(fn c -> [c.name | c.aliases || []] end)
        |> Enum.uniq()

      # Guard against a vacuous pass if the catalog is ever empty here.
      assert names != []

      misclassified = Enum.filter(names, &EquipmentDetector.is_equipment?(&1, lookup: lookup))

      assert misclassified == [],
             """
             These canonical ingredients are being filtered out as kitchen equipment,
             so they can never match during parsing:

             #{Enum.map_join(misclassified, "\n", &"  - #{&1}")}

             Either rename the canonical or adjust EquipmentDetector.
             """
    end

    test "genuine equipment is still detected", %{lookup: lookup} do
      for item <- @genuine_equipment do
        assert EquipmentDetector.is_equipment?(item, lookup: lookup),
               "expected #{inspect(item)} to be detected as equipment"
      end
    end
  end

  describe "is_equipment?/1 without a lookup" do
    test "sprays are ingredients, not equipment" do
      # These were listed as equipment phrases; they are release-agent fats and
      # contribute calories, so nutrition needs them.
      refute EquipmentDetector.is_equipment?("cooking spray")
      refute EquipmentDetector.is_equipment?("baking spray")
      refute EquipmentDetector.is_equipment?("nonstick spray")
    end

    test "falls back to heuristics" do
      assert EquipmentDetector.is_equipment?("A thermometer")
      refute EquipmentDetector.is_equipment?("2 cups flour")
      refute EquipmentDetector.is_equipment?(nil)
    end
  end
end
