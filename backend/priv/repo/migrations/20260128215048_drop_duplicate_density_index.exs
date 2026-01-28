defmodule Controlcopypasta.Repo.Migrations.DropDuplicateDensityIndex do
  use Ecto.Migration

  def up do
    # The _unique_combo index doesn't handle NULL preparations correctly
    # (NULL != NULL in SQL, allowing duplicates). The _unique_idx index
    # uses COALESCE to treat NULL as '' and is the one we use for upserts.
    drop_if_exists index(:ingredient_densities, [],
      name: :ingredient_densities_unique_combo
    )
  end

  def down do
    create_if_not_exists unique_index(
      :ingredient_densities,
      [:canonical_ingredient_id, :volume_unit, :preparation],
      name: :ingredient_densities_unique_combo
    )
  end
end
