defmodule ControlcopypastaWeb.BrowseController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Nutrition.Calculator

  action_fallback ControlcopypastaWeb.FallbackController

  def domains(conn, _params) do
    domains = Recipes.list_domains()
    render(conn, :domains, domains: domains)
  end

  def recipes_by_domain(conn, %{"domain" => domain} = params) do
    user = conn.assigns.current_user
    params = maybe_add_avoided_filter(params, user)

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

  def nutrition(conn, %{"domain" => domain, "id" => id} = params) do
    servings_override = Map.get(params, "servings")

    case Recipes.get_recipe_by_domain(domain, id) do
      nil ->
        {:error, :not_found}

      recipe ->
        opts = if servings_override, do: [servings_override: parse_int(servings_override, nil)], else: []
        nutrition = Calculator.calculate_recipe_nutrition(recipe, opts)
        render(conn, :nutrition, nutrition: nutrition, recipe: recipe)
    end
  end

  # Check if we should filter out avoided ingredients
  defp maybe_add_avoided_filter(params, user) do
    # Check if hide_avoided param is explicitly set, or use user preference
    hide_avoided =
      case Map.get(params, "hide_avoided") do
        "true" -> true
        "false" -> false
        _ -> user.hide_avoided_ingredients
      end

    if hide_avoided do
      avoided_ids = Accounts.get_avoided_canonical_ids(user.id)

      if MapSet.size(avoided_ids) > 0 do
        Map.put(params, "exclude_ingredient_ids", MapSet.to_list(avoided_ids))
      else
        params
      end
    else
      params
    end
  end

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val), do: val
  defp parse_int(_, default), do: default
end
