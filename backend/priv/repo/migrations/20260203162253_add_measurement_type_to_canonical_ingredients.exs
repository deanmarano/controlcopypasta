defmodule Controlcopypasta.Repo.Migrations.AddMeasurementTypeToCanonicalIngredients do
  use Ecto.Migration

  def change do
    alter table(:canonical_ingredients) do
      add :measurement_type, :string, default: "standard"
    end

    create index(:canonical_ingredients, [:measurement_type])
  end
end
