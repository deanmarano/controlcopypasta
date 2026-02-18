defmodule ControlcopypastaWeb.QuicklistJSON do
  alias Controlcopypasta.Recipes.Recipe

  def batch(%{recipes: recipes, user_id: user_id}) do
    %{data: Enum.map(recipes, &recipe_summary(&1, user_id))}
  end

  def maybe_list(%{recipes: recipes, user_id: user_id}) do
    %{data: Enum.map(recipes, &recipe_summary(&1, user_id))}
  end

  defp recipe_summary(%Recipe{} = recipe, user_id) do
    %{
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      source_url: recipe.source_url,
      source_domain: recipe.source_domain,
      image_url: recipe.image_url,
      total_time_minutes: recipe.total_time_minutes,
      servings: recipe.servings,
      tags: Enum.map(recipe.tags, fn tag -> %{id: tag.id, name: tag.name} end),
      inserted_at: recipe.inserted_at,
      is_owned: recipe.user_id == user_id
    }
  end
end
