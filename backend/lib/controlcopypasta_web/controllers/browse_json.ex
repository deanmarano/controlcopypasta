defmodule ControlcopypastaWeb.BrowseJSON do
  alias Controlcopypasta.Recipes.Recipe

  def domains(%{domains: domains}) do
    %{data: domains}
  end

  def recipes(%{recipes: recipes, total: total}) do
    %{data: for(recipe <- recipes, do: recipe_data(recipe)), total: total}
  end

  def recipe(%{recipe: recipe}) do
    %{data: recipe_data(recipe)}
  end

  def nutrition(%{nutrition: nutrition, recipe: recipe}) do
    %{
      data: %{
        recipe_id: recipe.id,
        recipe_title: recipe.title,
        servings: nutrition.servings,
        completeness: nutrition.completeness,
        total: nutrition_data(nutrition.total),
        per_serving: nutrition_data(nutrition.per_serving),
        ingredients: Enum.map(nutrition.ingredients, &ingredient_nutrition_data/1),
        warnings: nutrition.warnings
      }
    }
  end

  # Format nutrition data - handles both range maps and scalar values
  defp nutrition_data(nutrients) do
    %{
      calories: format_nutrient_value(nutrients[:calories]),
      protein_g: format_nutrient_value(nutrients[:protein_g]),
      fat_total_g: format_nutrient_value(nutrients[:fat_total_g]),
      fat_saturated_g: format_nutrient_value(nutrients[:fat_saturated_g]),
      carbohydrates_g: format_nutrient_value(nutrients[:carbohydrates_g]),
      fiber_g: format_nutrient_value(nutrients[:fiber_g]),
      sugar_g: format_nutrient_value(nutrients[:sugar_g]),
      sodium_mg: format_nutrient_value(nutrients[:sodium_mg]),
      cholesterol_mg: format_nutrient_value(nutrients[:cholesterol_mg]),
      potassium_mg: format_nutrient_value(nutrients[:potassium_mg]),
      calcium_mg: format_nutrient_value(nutrients[:calcium_mg]),
      iron_mg: format_nutrient_value(nutrients[:iron_mg]),
      vitamin_a_mcg: format_nutrient_value(nutrients[:vitamin_a_mcg]),
      vitamin_c_mg: format_nutrient_value(nutrients[:vitamin_c_mg]),
      vitamin_d_mcg: format_nutrient_value(nutrients[:vitamin_d_mcg])
    }
  end

  # Format a nutrient value - pass through range maps, convert scalars
  defp format_nutrient_value(%{min: _, best: _, max: _, confidence: _} = range), do: range
  defp format_nutrient_value(nil), do: nil
  defp format_nutrient_value(value) when is_number(value) do
    %{min: value, best: value, max: value, confidence: 1.0}
  end

  defp ingredient_nutrition_data(ing) do
    %{
      original: ing.original,
      status: ing.status,
      canonical_name: ing.canonical_name,
      canonical_id: ing.canonical_id,
      quantity: ing.quantity,
      quantity_min: ing[:quantity_min],
      quantity_max: ing[:quantity_max],
      unit: ing.unit,
      grams: format_nutrient_value(ing.grams),
      calories: format_nutrient_value(ing.calories),
      protein_g: format_nutrient_value(ing.protein_g),
      carbohydrates_g: format_nutrient_value(ing.carbohydrates_g),
      fat_total_g: format_nutrient_value(ing.fat_total_g),
      error: ing.error
    }
  end

  defp recipe_data(%Recipe{} = recipe) do
    %{
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      source_url: recipe.source_url,
      source_domain: recipe.source_domain,
      image_url: recipe.image_url,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      prep_time_minutes: recipe.prep_time_minutes,
      cook_time_minutes: recipe.cook_time_minutes,
      total_time_minutes: recipe.total_time_minutes,
      servings: recipe.servings,
      notes: recipe.notes,
      tags: Enum.map(recipe.tags, &tag_data/1),
      archived_at: recipe.archived_at,
      inserted_at: recipe.inserted_at,
      updated_at: recipe.updated_at
    }
  end

  defp tag_data(tag) do
    %{
      id: tag.id,
      name: tag.name
    }
  end
end
