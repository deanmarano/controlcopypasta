defmodule ControlcopypastaWeb.BrowseController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Nutrition.Calculator

  action_fallback ControlcopypastaWeb.FallbackController

  def domains(conn, _params) do
    domains = Recipes.list_domains()
    render(conn, :domains, domains: domains)
  end

  def screenshot(conn, %{"domain" => domain}) do
    case Recipes.get_domain_screenshot(domain) do
      nil ->
        conn |> send_resp(404, "") |> halt()

      screenshot_binary ->
        conn
        |> put_resp_content_type("image/png")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, screenshot_binary)
    end
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
    source = parse_source_param(Map.get(params, "source"))

    case Recipes.get_recipe_by_domain(domain, id) do
      nil ->
        {:error, :not_found}

      recipe ->
        opts = [
          servings_override: if(servings_override, do: parse_int(servings_override, nil)),
          source: source
        ] |> Enum.reject(fn {_k, v} -> is_nil(v) end)

        nutrition = Calculator.calculate_recipe_nutrition(recipe, opts)
        render(conn, :nutrition, nutrition: nutrition, recipe: recipe)
    end
  end

  # Parse source parameter into atom, default to :composite
  defp parse_source_param(nil), do: :composite
  defp parse_source_param(source) when is_binary(source) do
    valid_sources = Calculator.valid_sources() |> Enum.map(&Atom.to_string/1)

    if source in valid_sources do
      String.to_existing_atom(source)
    else
      :composite
    end
  end
  defp parse_source_param(_), do: :composite

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
        avoided_names = Ingredients.list_canonical_names_by_ids(avoided_ids)

        params
        |> Map.put("exclude_ingredient_ids", MapSet.to_list(avoided_ids))
        |> Map.put("exclude_ingredient_names", avoided_names)
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
