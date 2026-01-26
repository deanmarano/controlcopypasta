defmodule Controlcopypasta.Repo.Migrations.AddIngredientsParsedAtToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :ingredients_parsed_at, :utc_datetime
    end

    create index(:recipes, [:ingredients_parsed_at])
  end
end
