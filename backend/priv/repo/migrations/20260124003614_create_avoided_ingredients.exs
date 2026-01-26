defmodule Controlcopypasta.Repo.Migrations.CreateAvoidedIngredients do
  use Ecto.Migration

  def change do
    create table(:avoided_ingredients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :canonical_name, :string, null: false
      add :display_name, :string, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:avoided_ingredients, [:user_id, :canonical_name])
    create index(:avoided_ingredients, [:user_id])
  end
end
