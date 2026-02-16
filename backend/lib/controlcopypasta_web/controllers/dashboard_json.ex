defmodule ControlcopypastaWeb.DashboardJSON do
  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Recipes.Recipe

  def index(%{
        dinner_ideas: dinner_ideas,
        recently_added: recently_added,
        this_time_last_year: this_time_last_year,
        avoided_set: avoided_set
      }) do
    %{
      data: %{
        dinner_ideas: Enum.map(dinner_ideas, &summary_with_avoided(&1, avoided_set)),
        recently_added: Enum.map(recently_added, &summary_with_avoided(&1, avoided_set)),
        this_time_last_year: Enum.map(this_time_last_year, &summary_with_avoided(&1, avoided_set))
      }
    }
  end

  defp summary(%Recipe{} = recipe) do
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
      inserted_at: recipe.inserted_at
    }
  end

  defp summary_with_avoided(%Recipe{} = recipe, avoided_set) do
    avoided_ingredients = Recipes.get_avoided_ingredients_in_recipe(recipe, avoided_set)

    summary(recipe)
    |> Map.merge(%{
      contains_avoided: length(avoided_ingredients) > 0,
      avoided_ingredients: avoided_ingredients
    })
  end
end
