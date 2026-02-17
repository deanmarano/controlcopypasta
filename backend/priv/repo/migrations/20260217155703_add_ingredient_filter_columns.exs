defmodule Controlcopypasta.Repo.Migrations.AddIngredientFilterColumns do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      # True when all ingredients have canonical_id or are skipped
      add :all_ingredients_parsed, :boolean, default: false, null: false
      # Flat array of canonical_ids extracted from ingredients JSONB
      add :ingredient_canonical_ids, {:array, :string}, default: [], null: false
    end

    # GIN index for fast overlap checks (ANY/&&) on avoided ingredient filtering
    create index(:recipes, [:ingredient_canonical_ids], using: "GIN")
    # Partial index for quickly finding parsed recipes
    create index(:recipes, [:all_ingredients_parsed], where: "all_ingredients_parsed = true")

    # Backfill from existing JSONB data
    execute(
      """
      UPDATE recipes SET
        all_ingredients_parsed = (
          jsonb_array_length(ingredients) > 0
          AND NOT EXISTS (
            SELECT 1 FROM jsonb_array_elements(ingredients) AS elem
            WHERE (elem->>'canonical_id' IS NULL OR elem->>'canonical_id' = '')
              AND (elem->>'skipped')::boolean IS NOT TRUE
          )
        ),
        ingredient_canonical_ids = COALESCE(
          (SELECT array_agg(DISTINCT elem->>'canonical_id')
           FROM jsonb_array_elements(ingredients) AS elem
           WHERE elem->>'canonical_id' IS NOT NULL AND elem->>'canonical_id' != ''),
          '{}'
        )
      """,
      # Down migration: columns will be dropped by alter table rollback
      ""
    )
  end
end
