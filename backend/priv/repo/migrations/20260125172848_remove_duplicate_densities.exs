defmodule Controlcopypasta.Repo.Migrations.RemoveDuplicateDensities do
  use Ecto.Migration

  def up do
    # Remove duplicate density entries, keeping the one with the earliest inserted_at
    # PostgreSQL treats NULL as distinct in unique constraints, so duplicates can exist
    execute """
    DELETE FROM ingredient_densities a
    USING ingredient_densities b
    WHERE a.id > b.id
      AND a.canonical_ingredient_id = b.canonical_ingredient_id
      AND a.volume_unit = b.volume_unit
      AND COALESCE(a.preparation, '') = COALESCE(b.preparation, '')
    """

    # Drop the old unique constraint that doesn't handle NULLs properly
    drop_if_exists unique_index(:ingredient_densities, [:canonical_ingredient_id, :volume_unit, :preparation])

    # Create a new unique index that treats NULL preparation as a single value
    # Using COALESCE to convert NULL to empty string for uniqueness check
    create unique_index(
      :ingredient_densities,
      ["canonical_ingredient_id", "volume_unit", "COALESCE(preparation, '')"],
      name: :ingredient_densities_unique_idx
    )
  end

  def down do
    drop_if_exists index(:ingredient_densities, [:canonical_ingredient_id, :volume_unit, :preparation], name: :ingredient_densities_unique_idx)

    create unique_index(:ingredient_densities, [:canonical_ingredient_id, :volume_unit, :preparation])
  end
end
