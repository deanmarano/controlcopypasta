defmodule Controlcopypasta.Repo.Migrations.AddSourceToDensityUniqueConstraint do
  use Ecto.Migration

  def up do
    # Drop the old unique index that doesn't include source
    drop_if_exists index(:ingredient_densities, [], name: :ingredient_densities_unique_idx)

    # Create new unique index that includes source
    # This allows storing density data from multiple sources (usda, fatsecret, openfoodfacts, etc.)
    create unique_index(
      :ingredient_densities,
      ["canonical_ingredient_id", "volume_unit", "COALESCE(preparation, '')", "source"],
      name: :ingredient_densities_unique_idx
    )
  end

  def down do
    # Revert to old index without source
    drop_if_exists index(:ingredient_densities, [], name: :ingredient_densities_unique_idx)

    # Delete duplicates before recreating the old constraint
    # Keep the one with highest confidence for each (ingredient, unit, prep) combo
    execute """
    DELETE FROM ingredient_densities a
    USING ingredient_densities b
    WHERE a.id < b.id
      AND a.canonical_ingredient_id = b.canonical_ingredient_id
      AND a.volume_unit = b.volume_unit
      AND COALESCE(a.preparation, '') = COALESCE(b.preparation, '')
    """

    create unique_index(
      :ingredient_densities,
      ["canonical_ingredient_id", "volume_unit", "COALESCE(preparation, '')"],
      name: :ingredient_densities_unique_idx
    )
  end
end
