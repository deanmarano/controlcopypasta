defmodule Controlcopypasta.Repo.Migrations.AddBrandPackageSizes do
  use Ecto.Migration

  def change do
    create table(:brand_package_sizes, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :canonical_ingredient_id,
          references(:canonical_ingredients, type: :binary_id, on_delete: :delete_all),
          null: false

      # Package description (e.g., "can", "bottle", "box", "bag")
      add :package_type, :string, null: false
      # Size value (e.g., 12, 16, 32)
      add :size_value, :decimal, null: false
      # Size unit (e.g., "oz", "ml", "g")
      add :size_unit, :string, null: false
      # Human-readable label (e.g., "12 oz can", "2L bottle")
      add :label, :string
      # Is this the most common/default size?
      add :is_default, :boolean, default: false
      # Sort order for displaying sizes
      add :sort_order, :integer, default: 0

      timestamps()
    end

    create index(:brand_package_sizes, [:canonical_ingredient_id])

    create unique_index(:brand_package_sizes, [
             :canonical_ingredient_id,
             :package_type,
             :size_value,
             :size_unit
           ])
  end
end
