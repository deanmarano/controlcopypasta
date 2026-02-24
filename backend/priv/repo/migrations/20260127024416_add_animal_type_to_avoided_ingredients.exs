defmodule Controlcopypasta.Repo.Migrations.AddAnimalTypeToAvoidedIngredients do
  use Ecto.Migration

  def change do
    alter table(:avoided_ingredients) do
      add :animal_type, :string
    end

    # Partial unique index for animal type avoidance
    create index(:avoided_ingredients, [:user_id, :animal_type],
             unique: true,
             where: "avoidance_type = 'animal' AND animal_type IS NOT NULL",
             name: :avoided_ingredients_user_animal_idx
           )
  end
end
