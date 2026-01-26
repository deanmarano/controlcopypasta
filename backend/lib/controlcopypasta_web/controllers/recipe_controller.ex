defmodule ControlcopypastaWeb.RecipeController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Similarity
  alias Controlcopypasta.Nutrition.Calculator

  action_fallback ControlcopypastaWeb.FallbackController

  def index(conn, params) do
    user = conn.assigns.current_user
    avoided_set = Accounts.get_avoided_canonical_names(user.id)
    recipes = Recipes.list_recipes_for_user(user.id, params)
    render(conn, :index, recipes: recipes, avoided_set: avoided_set)
  end

  def create(conn, %{"recipe" => recipe_params}) do
    user = conn.assigns.current_user
    recipe_params = Map.put(recipe_params, "user_id", user.id)

    with {:ok, %Recipe{} = recipe} <- Recipes.create_recipe(recipe_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/recipes/#{recipe}")
      |> render(:show, recipe: recipe)
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    avoided_set = Accounts.get_avoided_canonical_names(user.id)

    case Recipes.get_recipe_for_user(user.id, id) do
      nil -> {:error, :not_found}
      recipe -> render(conn, :show, recipe: recipe, avoided_set: avoided_set)
    end
  end

  def update(conn, %{"id" => id, "recipe" => recipe_params}) do
    user = conn.assigns.current_user

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      recipe ->
        with {:ok, %Recipe{} = recipe} <- Recipes.update_recipe(recipe, recipe_params) do
          render(conn, :show, recipe: recipe)
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      recipe ->
        with {:ok, %Recipe{}} <- Recipes.delete_recipe(recipe) do
          send_resp(conn, :no_content, "")
        end
    end
  end

  def archive(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      recipe ->
        with {:ok, %Recipe{} = recipe} <- Recipes.archive_recipe(recipe) do
          render(conn, :show, recipe: recipe)
        end
    end
  end

  def unarchive(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      recipe ->
        with {:ok, %Recipe{} = recipe} <- Recipes.unarchive_recipe(recipe) do
          render(conn, :show, recipe: recipe)
        end
    end
  end

  def parse(conn, %{"url" => url}) do
    case Controlcopypasta.Parser.parse_url(url) do
      {:ok, recipe_data} ->
        render(conn, :parsed, recipe: recipe_data)

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: reason)
    end
  end

  def parse(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: "URL is required")
  end

  def similar(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    limit = Map.get(params, "limit", "5") |> parse_int(5) |> min(20)

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      recipe ->
        similar_recipes = Similarity.find_similar(recipe, limit: limit, user_id: user.id)
        render(conn, :similar, similar: similar_recipes)
    end
  end

  def compare(conn, %{"id" => id, "compare_id" => compare_id}) do
    user = conn.assigns.current_user

    with recipe1 when not is_nil(recipe1) <- Recipes.get_recipe_for_user(user.id, id),
         recipe2 when not is_nil(recipe2) <- Recipes.get_recipe_for_user(user.id, compare_id) do
      comparison = Similarity.compare(recipe1, recipe2)
      render(conn, :comparison, comparison: comparison, recipe1: recipe1, recipe2: recipe2)
    else
      nil -> {:error, :not_found}
    end
  end

  def nutrition(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    servings_override = Map.get(params, "servings")

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      recipe ->
        opts = if servings_override, do: [servings_override: parse_int(servings_override, nil)], else: []
        nutrition = Calculator.calculate_recipe_nutrition(recipe, opts)
        render(conn, :nutrition, nutrition: nutrition, recipe: recipe)
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
