defmodule Controlcopypasta.Repo.Migrations.CreateIngredientDensities do
  use Ecto.Migration

  def change do
    create table(:ingredient_densities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :canonical_ingredient_id, references(:canonical_ingredients, type: :binary_id, on_delete: :delete_all), null: false

      # The volume unit this density applies to
      add :volume_unit, :string, null: false  # "cup", "tbsp", "tsp"

      # Weight in grams for one unit of volume
      add :grams_per_unit, :decimal, null: false

      # Optional preparation that affects density
      add :preparation, :string  # nil, "packed", "sifted", "chopped", etc.

      # Data source
      add :source, :string, null: false  # "usda", "manual", "calculated"

      # Notes about this density measurement
      add :notes, :string

      timestamps()
    end

    create index(:ingredient_densities, [:canonical_ingredient_id])
    create index(:ingredient_densities, [:volume_unit])

    # Unique constraint: one density per ingredient/unit/preparation combination
    create unique_index(:ingredient_densities, [:canonical_ingredient_id, :volume_unit, :preparation],
      name: :ingredient_densities_unique_combo
    )
  end
end
