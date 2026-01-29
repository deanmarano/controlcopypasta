defmodule Controlcopypasta.Repo.Migrations.CreateRecipeReferences do
  use Ecto.Migration

  def change do
    create table(:recipe_references, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :parent_recipe_id, references(:recipes, type: :binary_id, on_delete: :delete_all), null: false
      add :child_recipe_id, references(:recipes, type: :binary_id, on_delete: :nilify_all)
      add :ingredient_index, :integer, null: false
      add :reference_type, :string, null: false  # below, above, notes, link, inline
      add :reference_text, :string
      add :extracted_name, :string
      add :resolved_at, :utc_datetime
      add :is_optional, :boolean, default: false

      timestamps()
    end

    create index(:recipe_references, [:parent_recipe_id])
    create index(:recipe_references, [:child_recipe_id])
    create unique_index(:recipe_references, [:parent_recipe_id, :ingredient_index])
  end
end
