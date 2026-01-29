defmodule ControlcopypastaWeb.RecipeJSON do
  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Recipes.Recipe

  def index(%{recipes: recipes, avoided_set: avoided_set}) do
    %{data: for(recipe <- recipes, do: data_with_avoided(recipe, avoided_set))}
  end

  def index(%{recipes: recipes}) do
    %{data: for(recipe <- recipes, do: data(recipe))}
  end

  def show(%{recipe: recipe, avoided_set: avoided_set}) do
    %{data: data_with_avoided(recipe, avoided_set)}
  end

  def show(%{recipe: recipe}) do
    %{data: data(recipe)}
  end

  def parsed(%{recipe: recipe_data}) do
    %{data: recipe_data}
  end

  def error(%{message: message}) do
    %{error: %{message: message}}
  end

  def similar(%{similar: similar_results}) do
    %{
      data:
        Enum.map(similar_results, fn result ->
          %{
            recipe: data(result.recipe),
            score: result.score,
            overlap_score: result.overlap_score,
            proportion_score: result.proportion_score,
            shared_ingredients: result.shared_ingredients,
            unique_to_other: result.unique_to_other
          }
        end)
    }
  end

  def comparison(%{comparison: comparison, recipe1: recipe1, recipe2: recipe2}) do
    %{
      data: %{
        recipe1: data(recipe1),
        recipe2: data(recipe2),
        score: comparison.score,
        overlap_score: comparison.overlap_score,
        proportion_score: comparison.proportion_score,
        shared_ingredients:
          Enum.map(comparison.shared_ingredients, fn {name, {p1, p2}} ->
            %{name: name, proportion1: p1, proportion2: p2}
          end),
        only_in_first:
          Enum.map(comparison.only_in_first, fn {name, proportion} ->
            %{name: name, proportion: proportion}
          end),
        only_in_second:
          Enum.map(comparison.only_in_second, fn {name, proportion} ->
            %{name: name, proportion: proportion}
          end)
      }
    }
  end

  def decisions(%{decisions: decisions}) do
    %{data: Enum.map(decisions, &decision_data/1)}
  end

  def decision(%{decision: decision}) do
    %{data: decision_data(decision)}
  end

  defp decision_data(decision) do
    %{
      id: decision.id,
      recipe_id: decision.recipe_id,
      ingredient_index: decision.ingredient_index,
      selected_canonical_id: decision.selected_canonical_id,
      selected_name: decision.selected_name,
      inserted_at: decision.inserted_at,
      updated_at: decision.updated_at
    }
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
    # Legacy scalar value - convert to range format for consistency
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

  defp data(%Recipe{} = recipe) do
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

  defp data_with_avoided(%Recipe{} = recipe, avoided_set) do
    avoided_ingredients = Recipes.get_avoided_ingredients_in_recipe(recipe, avoided_set)

    data(recipe)
    |> Map.merge(%{
      contains_avoided: length(avoided_ingredients) > 0,
      avoided_ingredients: avoided_ingredients
    })
  end

  defp tag_data(tag) do
    %{
      id: tag.id,
      name: tag.name
    }
  end
end
