defmodule Controlcopypasta.Repo.Migrations.AddProvenanceToIngredientDensities do
  use Ecto.Migration

  def change do
    alter table(:ingredient_densities) do
      # Add provenance fields (matching IngredientNutrition pattern)
      # USDA portion ID or FatSecret serving_id
      add :source_id, :string
      # Link to source data
      add :source_url, :string
      # 0.0-1.0 data quality score
      add :confidence, :decimal
      # USDA: number of measurements
      add :data_points, :integer
      # When fetched from API
      add :retrieved_at, :utc_datetime
      add :last_checked_at, :utc_datetime
    end

    # Add index for source lookups
    create index(:ingredient_densities, [:source, :source_id])
  end
end
