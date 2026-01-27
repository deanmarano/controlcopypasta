defmodule Controlcopypasta.Repo.Migrations.AddExceptionsToAvoidedIngredients do
  use Ecto.Migration

  def change do
    alter table(:avoided_ingredients) do
      # Array of canonical_ingredient_ids that are exceptions to this avoidance
      # Only used for category and allergen avoidance types
      add :exceptions, {:array, :binary_id}, default: []
    end
  end
end
