defmodule Controlcopypasta.Repo.Migrations.AddNutritionToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      # Per-serving nutrition from Schema.org JSON-LD
      add :nutrition_serving_size, :string
      add :nutrition_calories, :decimal
      add :nutrition_protein_g, :decimal
      add :nutrition_fat_g, :decimal
      add :nutrition_saturated_fat_g, :decimal
      add :nutrition_trans_fat_g, :decimal
      add :nutrition_carbohydrates_g, :decimal
      add :nutrition_fiber_g, :decimal
      add :nutrition_sugar_g, :decimal
      add :nutrition_sodium_mg, :decimal
      add :nutrition_cholesterol_mg, :decimal
    end
  end
end
