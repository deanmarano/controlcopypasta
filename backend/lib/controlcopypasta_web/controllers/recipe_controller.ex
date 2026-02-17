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

  def copy(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Recipes.copy_recipe(id, user.id) do
      {:ok, %Recipe{} = recipe} ->
        conn
        |> put_status(:created)
        |> render(:show, recipe: recipe)

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    avoided_set = Accounts.get_avoided_canonical_names(user.id)

    # Try user's own recipes first, then fall back to any recipe (for discovered recipes)
    recipe = Recipes.get_recipe_for_user(user.id, id) || Recipes.get_recipe(id)

    case recipe do
      nil -> {:error, :not_found}
      recipe -> render(conn, :show, recipe: recipe, avoided_set: avoided_set, user_id: user.id)
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

    case Recipes.get_recipe_for_user(user.id, id) || Recipes.get_recipe(id) do
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

  # Ingredient Decisions

  def list_decisions(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Recipes.get_recipe_for_user(user.id, id) || Recipes.get_recipe(id) do
      nil ->
        {:error, :not_found}

      _recipe ->
        decisions = Recipes.list_decisions(id, user.id)
        render(conn, :decisions, decisions: decisions)
    end
  end

  def save_decision(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      _recipe ->
        attrs = %{
          recipe_id: id,
          user_id: user.id,
          ingredient_index: params["ingredient_index"],
          selected_canonical_id: params["selected_canonical_id"],
          selected_name: params["selected_name"]
        }

        case Recipes.save_decision(attrs) do
          {:ok, decision} ->
            conn
            |> put_status(:created)
            |> render(:decision, decision: decision)

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def delete_decision(conn, %{"id" => id, "ingredient_index" => index}) do
    user = conn.assigns.current_user

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      _recipe ->
        {count, _} = Recipes.delete_decision(id, user.id, parse_int(index, 0))
        json(conn, %{deleted: count > 0})
    end
  end

  def clear_decisions(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Recipes.get_recipe_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      _recipe ->
        {count, _} = Recipes.clear_decisions(id, user.id)
        json(conn, %{deleted: count})
    end
  end

  def nutrition(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    servings_override = Map.get(params, "servings")
    decisions_params = Map.get(params, "decisions", %{})
    source = parse_source_param(Map.get(params, "source"))

    case Recipes.get_recipe_for_user(user.id, id) || Recipes.get_recipe(id) do
      nil ->
        {:error, :not_found}

      recipe ->
        # Build decisions map from params or user's saved decisions
        decisions = if map_size(decisions_params) > 0 do
          decisions_params
          |> Enum.map(fn {idx, canonical_id} ->
            {parse_int(idx, 0), %{selected_canonical_id: canonical_id}}
          end)
          |> Map.new()
        else
          Recipes.get_decisions_map(id, user.id)
        end

        opts = [
          servings_override: if(servings_override, do: parse_int(servings_override, nil)),
          decisions: decisions,
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

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val), do: val
  defp parse_int(_, default), do: default
end
