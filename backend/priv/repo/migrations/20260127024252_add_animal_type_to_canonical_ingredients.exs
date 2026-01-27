defmodule Controlcopypasta.Repo.Migrations.AddAnimalTypeToCanonicalIngredients do
  use Ecto.Migration

  def change do
    alter table(:canonical_ingredients) do
      add :animal_type, :string
    end

    create index(:canonical_ingredients, [:animal_type])
  end
end
