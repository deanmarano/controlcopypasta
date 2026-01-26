defmodule Controlcopypasta.Repo.Migrations.AddConfidenceToIngredientNutrition do
  use Ecto.Migration

  def change do
    alter table(:ingredient_nutrition) do
      # Confidence score (0.0 to 1.0)
      add :confidence, :decimal, precision: 3, scale: 2

      # Breakdown of factors that contributed to the confidence score
      # Example: %{
      #   "source_reliability" => 0.9,
      #   "data_completeness" => 0.8,
      #   "serving_size_match" => 1.0,
      #   "staleness_penalty" => 0.0,
      #   "cross_source_agreement" => 0.85
      # }
      add :confidence_factors, :map

      # When the nutrition data was originally retrieved from the source
      add :retrieved_at, :utc_datetime

      # Last time we checked if the source data is still valid/current
      add :last_checked_at, :utc_datetime
    end

    # Index for finding low-confidence entries that need improvement
    create index(:ingredient_nutrition, [:confidence])

    # Composite index for prioritizing which ingredients need attention
    # (low confidence + high usage = high priority to fix)
    create index(:ingredient_nutrition, [:is_primary, :confidence])
  end
end
