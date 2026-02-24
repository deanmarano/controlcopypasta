defmodule Controlcopypasta.Repo.Migrations.CreateIngredientNutrition do
  use Ecto.Migration

  def change do
    # Enum for data sources, ordered by trust level
    execute(
      "CREATE TYPE nutrition_source AS ENUM ('usda', 'manual', 'open_food_facts', 'nutritionix', 'estimated')",
      "DROP TYPE nutrition_source"
    )

    create table(:ingredient_nutrition, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :canonical_ingredient_id,
          references(:canonical_ingredients, type: :binary_id, on_delete: :delete_all),
          null: false

      # Data source tracking
      add :source, :nutrition_source, null: false
      # External ID (e.g., USDA FDC ID: "171287")
      add :source_id, :string
      # Human-readable source description
      add :source_name, :string
      # Link to source data
      add :source_url, :string

      # Reference amount (what the nutrition values are based on)
      # e.g., 100
      add :serving_size_value, :decimal, null: false
      # e.g., "g", "ml"
      add :serving_size_unit, :string, null: false
      # e.g., "1 cup chopped", "1 medium"
      add :serving_description, :string

      # Macronutrients (all per serving_size)
      # kcal
      add :calories, :decimal
      # grams
      add :protein_g, :decimal
      # grams
      add :fat_total_g, :decimal
      # grams
      add :fat_saturated_g, :decimal
      # grams
      add :fat_trans_g, :decimal
      add :fat_polyunsaturated_g, :decimal
      add :fat_monounsaturated_g, :decimal
      # grams
      add :carbohydrates_g, :decimal
      # grams
      add :fiber_g, :decimal
      # grams
      add :sugar_g, :decimal
      # grams
      add :sugar_added_g, :decimal

      # Minerals
      add :sodium_mg, :decimal
      add :potassium_mg, :decimal
      add :calcium_mg, :decimal
      add :iron_mg, :decimal
      add :magnesium_mg, :decimal
      add :phosphorus_mg, :decimal
      add :zinc_mg, :decimal

      # Vitamins
      # RAE (retinol activity equivalents)
      add :vitamin_a_mcg, :decimal
      add :vitamin_c_mg, :decimal
      add :vitamin_d_mcg, :decimal
      add :vitamin_e_mg, :decimal
      add :vitamin_k_mcg, :decimal
      add :vitamin_b6_mg, :decimal
      add :vitamin_b12_mcg, :decimal
      add :folate_mcg, :decimal
      # B1
      add :thiamin_mg, :decimal
      # B2
      add :riboflavin_mg, :decimal
      # B3
      add :niacin_mg, :decimal

      # Other
      add :cholesterol_mg, :decimal
      add :water_g, :decimal

      # Metadata
      # Preferred source for this ingredient
      add :is_primary, :boolean, default: false
      # When manually verified
      add :verified_at, :utc_datetime
      # Any notes about the data
      add :notes, :text

      timestamps()
    end

    create index(:ingredient_nutrition, [:canonical_ingredient_id])
    create index(:ingredient_nutrition, [:source])
    create index(:ingredient_nutrition, [:is_primary])
    create unique_index(:ingredient_nutrition, [:canonical_ingredient_id, :source, :source_id])

    # Ensure only one primary per ingredient
    create unique_index(:ingredient_nutrition, [:canonical_ingredient_id],
             where: "is_primary = true",
             name: :ingredient_nutrition_one_primary_per_ingredient
           )
  end
end
