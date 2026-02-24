defmodule Controlcopypasta.Repo.Migrations.RelaxNutritionPrimaryConstraint do
  use Ecto.Migration

  def up do
    # Drop the unique constraint that only allows one primary nutrition source per ingredient.
    # This was blocking multi-source nutrition storage. The is_primary field is now advisory
    # (used as a manual override) rather than enforced by a constraint.
    drop_if_exists unique_index(:ingredient_nutrition, [:canonical_ingredient_id],
                     where: "is_primary = true",
                     name: :ingredient_nutrition_one_primary_per_ingredient
                   )
  end

  def down do
    # Re-create the constraint (may fail if data has multiple primaries)
    create unique_index(:ingredient_nutrition, [:canonical_ingredient_id],
             where: "is_primary = true",
             name: :ingredient_nutrition_one_primary_per_ingredient
           )
  end
end
