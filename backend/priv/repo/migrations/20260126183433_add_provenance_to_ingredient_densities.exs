defmodule Controlcopypasta.Repo.Migrations.AddProvenanceToIngredientDensities do
  use Ecto.Migration

  def change do
    alter table(:ingredient_densities) do
      # Add provenance fields (matching IngredientNutrition pattern)
      add :source_id, :string          # USDA portion ID or FatSecret serving_id
      add :source_url, :string         # Link to source data
      add :confidence, :decimal        # 0.0-1.0 data quality score
      add :data_points, :integer       # USDA: number of measurements
      add :retrieved_at, :utc_datetime # When fetched from API
      add :last_checked_at, :utc_datetime
    end

    # Add index for source lookups
    create index(:ingredient_densities, [:source, :source_id])
  end
end
