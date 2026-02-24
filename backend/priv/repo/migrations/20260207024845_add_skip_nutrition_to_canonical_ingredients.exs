defmodule Controlcopypasta.Repo.Migrations.AddSkipNutritionToCanonicalIngredients do
  use Ecto.Migration

  def change do
    alter table(:canonical_ingredients) do
      add :skip_nutrition, :boolean, default: false, null: false
    end

    # Mark common items that don't need nutrition data
    execute """
              UPDATE canonical_ingredients
              SET skip_nutrition = true
              WHERE name IN ('water', 'ice', 'ice water', 'cold water', 'hot water', 'boiling water', 'salt', 'kosher salt', 'sea salt', 'table salt', 'msg', 'monosodium glutamate')
            """,
            ""
  end
end
