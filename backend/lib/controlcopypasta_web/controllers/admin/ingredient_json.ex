defmodule ControlcopypastaWeb.Admin.IngredientJSON do
  @doc """
  Renders a list of ingredients for admin.
  """
  def index(%{ingredients: ingredients}) do
    %{data: for(ingredient <- ingredients, do: data(ingredient))}
  end

  @doc """
  Renders a single ingredient.
  """
  def show(%{ingredient: ingredient}) do
    %{data: data(ingredient)}
  end

  @doc """
  Renders options for admin forms.
  """
  def options(%{categories: categories, animal_types: animal_types}) do
    %{
      categories: categories,
      animal_types: animal_types
    }
  end

  defp data(ingredient) do
    %{
      id: ingredient.id,
      name: ingredient.name,
      display_name: ingredient.display_name,
      category: ingredient.category,
      subcategory: ingredient.subcategory,
      animal_type: ingredient.animal_type,
      tags: ingredient.tags || [],
      usage_count: ingredient.usage_count || 0
    }
  end
end
