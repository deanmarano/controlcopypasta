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
