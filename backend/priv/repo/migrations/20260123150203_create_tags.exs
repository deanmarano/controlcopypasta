defmodule Controlcopypasta.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:tags, [:name])

    create table(:recipe_tags, primary_key: false) do
      add :recipe_id, references(:recipes, type: :binary_id, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, type: :binary_id, on_delete: :delete_all), null: false
    end

    create unique_index(:recipe_tags, [:recipe_id, :tag_id])
    create index(:recipe_tags, [:tag_id])
  end
end
