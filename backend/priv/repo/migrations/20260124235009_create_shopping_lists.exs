defmodule Controlcopypasta.Repo.Migrations.CreateShoppingLists do
  use Ecto.Migration

  def change do
    create table(:shopping_lists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :archived_at, :utc_datetime

      timestamps()
    end

    create index(:shopping_lists, [:user_id])

    create table(:shopping_list_items, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :shopping_list_id,
          references(:shopping_lists, type: :binary_id, on_delete: :delete_all),
          null: false

      add :display_text, :string, size: 500, null: false
      add :quantity, :decimal
      add :unit, :string, size: 50

      add :canonical_ingredient_id,
          references(:canonical_ingredients, type: :binary_id, on_delete: :nilify_all)

      add :canonical_name, :string
      add :raw_name, :string
      add :category, :string, size: 100, default: "other"
      add :checked_at, :utc_datetime
      add :notes, :text
      add :source_recipe_ids, {:array, :binary_id}, default: []

      timestamps()
    end

    create index(:shopping_list_items, [:shopping_list_id])
    create index(:shopping_list_items, [:canonical_ingredient_id])
  end
end
