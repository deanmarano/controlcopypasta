defmodule Controlcopypasta.Repo.Migrations.AddSimilarityNameToCanonicalIngredients do
  use Ecto.Migration

  def change do
    alter table(:canonical_ingredients) do
      add :similarity_name, :string
    end

    create index(:canonical_ingredients, [:similarity_name])
  end
end
