defmodule Controlcopypasta.Repo.Migrations.CreatePendingIngredients do
  use Ecto.Migration

  def change do
    create table(:pending_ingredients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :occurrence_count, :integer, default: 1
      add :sample_texts, {:array, :string}, default: []
      add :status, :string, default: "pending"  # pending, approved, rejected, merged

      # FatSecret data (pre-populated if found)
      add :fatsecret_id, :string
      add :fatsecret_name, :string
      add :fatsecret_data, :map

      # Suggested values (can be edited by admin)
      add :suggested_display_name, :string
      add :suggested_category, :string
      add :suggested_aliases, {:array, :string}, default: []

      # If merged into existing canonical
      add :merged_into_id, references(:canonical_ingredients, type: :binary_id, on_delete: :nilify_all)

      # Tracking
      add :reviewed_at, :utc_datetime
      add :reviewed_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:pending_ingredients, [:name])
    create index(:pending_ingredients, [:status])
    create index(:pending_ingredients, [:occurrence_count])
  end
end
