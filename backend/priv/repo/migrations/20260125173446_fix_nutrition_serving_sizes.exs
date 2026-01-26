defmodule Controlcopypasta.Repo.Migrations.FixNutritionServingSizes do
  use Ecto.Migration

  @doc """
  Fixes serving_size_value for USDA nutrition entries.

  USDA FoodData Central returns nutrient values per 100g, but also includes
  a separate "serving size" field (like 4g for 1 tsp of sugar). The seeder
  was incorrectly storing this serving size instead of 100g, causing
  nutrition calculations to be wildly incorrect (e.g., 19,250 calories
  for 200g of sugar instead of ~770).

  This migration normalizes all USDA entries to use 100g as the serving size.
  """
  def up do
    # Fix all USDA entries - nutrient values are always per 100g
    execute """
    UPDATE ingredient_nutrition
    SET serving_size_value = 100,
        serving_size_unit = 'g'
    WHERE source = 'usda'
      AND serving_size_value != 100
    """

    # Also fix Open Food Facts entries which should also be per 100g
    execute """
    UPDATE ingredient_nutrition
    SET serving_size_value = 100,
        serving_size_unit = 'g'
    WHERE source = 'open_food_facts'
      AND serving_size_value != 100
    """
  end

  def down do
    # Cannot restore original values - this is a data fix
    :ok
  end
end
