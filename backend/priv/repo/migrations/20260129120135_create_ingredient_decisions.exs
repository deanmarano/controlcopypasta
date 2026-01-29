defmodule Controlcopypasta.Repo.Migrations.CreateIngredientDecisions do
  use Ecto.Migration

  def change do
    create table(:ingredient_decisions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :recipe_id, references(:recipes, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :ingredient_index, :integer, null: false
      add :selected_canonical_id, :binary_id, null: false
      add :selected_name, :string

      timestamps()
    end

    create unique_index(:ingredient_decisions, [:recipe_id, :user_id, :ingredient_index])
    create index(:ingredient_decisions, [:user_id])
  end
end
