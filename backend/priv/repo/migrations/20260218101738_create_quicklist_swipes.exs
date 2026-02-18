defmodule Controlcopypasta.Repo.Migrations.CreateQuicklistSwipes do
  use Ecto.Migration

  def change do
    create table(:quicklist_swipes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :recipe_id, references(:recipes, type: :binary_id, on_delete: :delete_all), null: false
      add :action, :string, null: false

      timestamps()
    end

    create unique_index(:quicklist_swipes, [:user_id, :recipe_id])
    create index(:quicklist_swipes, [:user_id, :action])
  end
end
