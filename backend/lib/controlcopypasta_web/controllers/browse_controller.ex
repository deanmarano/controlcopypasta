defmodule ControlcopypastaWeb.BrowseController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Recipes

  action_fallback ControlcopypastaWeb.FallbackController

  def domains(conn, _params) do
    domains = Recipes.list_domains()
    render(conn, :domains, domains: domains)
  end

  def recipes_by_domain(conn, %{"domain" => domain} = params) do
    recipes = Recipes.list_recipes_by_domain(domain, params)
    total = Recipes.count_recipes_by_domain(domain, params)
    render(conn, :recipes, recipes: recipes, total: total)
  end

  def show_recipe(conn, %{"domain" => domain, "id" => id}) do
    case Recipes.get_recipe_by_domain(domain, id) do
      nil -> {:error, :not_found}
      recipe -> render(conn, :recipe, recipe: recipe)
    end
  end
end
