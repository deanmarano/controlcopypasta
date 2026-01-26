defmodule Controlcopypasta.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    create table(:recipes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :source_url, :text
      add :source_domain, :string
      add :image_url, :text
      add :ingredients, :jsonb, default: "[]"
      add :instructions, :jsonb, default: "[]"
      add :prep_time_minutes, :integer
      add :cook_time_minutes, :integer
      add :total_time_minutes, :integer
      add :servings, :string
      add :notes, :text

      timestamps()
    end

    create index(:recipes, [:source_domain])
    create index(:recipes, [:title])
  end
end
