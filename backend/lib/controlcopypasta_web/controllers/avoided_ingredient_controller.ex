defmodule ControlcopypastaWeb.AvoidedIngredientController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Accounts.AvoidedIngredient
  alias Controlcopypasta.Ingredients

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Creates multiple avoided ingredients in bulk.
  Accepts {"avoidances": [{"type": "allergen", "value": "dairy"}, ...]}
  """
  def bulk_create(conn, %{"avoidances" => avoidances}) when is_list(avoidances) do
    user = conn.assigns.current_user

    case Accounts.create_avoided_ingredients_bulk(user.id, avoidances) do
      {:ok, created} ->
        conn
        |> put_status(:created)
        |> json(%{data: %{created_count: length(created)}})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to create avoidances: #{inspect(reason)}"})
    end
  end

  def index(conn, _params) do
    user = conn.assigns.current_user
    avoided_ingredients = Accounts.list_avoided_ingredients(user.id)
    render(conn, :index, avoided_ingredients: avoided_ingredients)
  end

  @doc """
  Creates an avoided ingredient.

  Supports four avoidance types:
  - "ingredient" (default): Avoid a specific ingredient by name or canonical ID
  - "category": Avoid all ingredients in a category (e.g., "dairy", "protein")
  - "allergen": Avoid all ingredients in an allergen group (e.g., "shellfish", "tree_nuts")
  - "animal": Avoid all ingredients of an animal type (e.g., "chicken", "beef", "pork")

  ## Examples

  Text-based ingredient avoidance (legacy):
      POST /api/avoided-ingredients
      {"avoided_ingredient": {"display_name": "chicken"}}

  Canonical ingredient avoidance (precise):
      POST /api/avoided-ingredients
      {"avoided_ingredient": {"display_name": "Chicken", "canonical_ingredient_id": "uuid"}}

  Category avoidance:
      POST /api/avoided-ingredients
      {"avoided_ingredient": {"avoidance_type": "category", "category": "dairy"}}

  Allergen avoidance:
      POST /api/avoided-ingredients
      {"avoided_ingredient": {"avoidance_type": "allergen", "allergen_group": "shellfish"}}

  Animal avoidance:
      POST /api/avoided-ingredients
      {"avoided_ingredient": {"avoidance_type": "animal", "animal_type": "chicken"}}
  """
  def create(conn, %{"avoided_ingredient" => params}) do
    user = conn.assigns.current_user
    avoidance_type = Map.get(params, "avoidance_type", "ingredient")

    result =
      case avoidance_type do
        "category" ->
          category = Map.get(params, "category")
          Accounts.create_avoided_category(user.id, category)

        "allergen" ->
          allergen_group = Map.get(params, "allergen_group")
          Accounts.create_avoided_allergen_group(user.id, allergen_group)

        "animal" ->
          animal_type = Map.get(params, "animal_type")
          Accounts.create_avoided_animal_type(user.id, animal_type)

        "ingredient" ->
          canonical_id = Map.get(params, "canonical_ingredient_id")

          if canonical_id do
            display_name = Map.get(params, "display_name", "")
            Accounts.create_avoided_ingredient_by_canonical(user.id, canonical_id, display_name)
          else
            Accounts.create_avoided_ingredient(user.id, params)
          end

        _ ->
          {:error, :invalid_avoidance_type}
      end

    case result do
      {:ok, %AvoidedIngredient{} = avoided} ->
        # Reload with preloaded association
        avoided = Accounts.get_avoided_ingredient(user.id, avoided.id)

        conn
        |> put_status(:created)
        |> render(:show, avoided_ingredient: avoided)

      {:error, :invalid_avoidance_type} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid avoidance type"})

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.get_avoided_ingredient(user.id, id) do
      nil ->
        {:error, :not_found}

      avoided ->
        with {:ok, %AvoidedIngredient{}} <- Accounts.delete_avoided_ingredient(avoided) do
          send_resp(conn, :no_content, "")
        end
    end
  end

  @doc """
  Returns the list of valid avoidance options.
  Useful for building UI selectors.
  """
  def options(conn, _params) do
    json(conn, %{
      avoidance_types: AvoidedIngredient.avoidance_types(),
      categories: AvoidedIngredient.valid_categories(),
      allergen_groups: AvoidedIngredient.valid_allergen_groups(),
      animal_types: AvoidedIngredient.valid_animal_types()
    })
  end

  @doc """
  Returns the ingredients included in an avoided category or allergen group.
  Includes whether each ingredient is an exception (allowed).
  """
  def show_ingredients(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.get_avoided_ingredient(user.id, id) do
      nil ->
        {:error, :not_found}

      %{avoidance_type: "ingredient"} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Cannot list ingredients for a single ingredient avoidance"})

      avoidance ->
        ingredients = get_ingredients_for_avoidance(avoidance)
        exceptions = MapSet.new(avoidance.exceptions || [])

        ingredients_with_status =
          Enum.map(ingredients, fn ing ->
            %{
              id: ing.id,
              name: ing.name,
              display_name: ing.display_name,
              category: ing.category,
              is_exception: MapSet.member?(exceptions, ing.id)
            }
          end)
          |> Enum.sort_by(& &1.display_name)

        json(conn, %{
          data: %{
            avoidance_id: avoidance.id,
            avoidance_type: avoidance.avoidance_type,
            display_name: avoidance.display_name,
            ingredients: ingredients_with_status,
            total_count: length(ingredients_with_status),
            exception_count: Enum.count(ingredients_with_status, & &1.is_exception)
          }
        })
    end
  end

  @doc """
  Adds an exception to a category or allergen avoidance.
  The ingredient will be allowed despite the category/allergen avoidance.
  """
  def add_exception(conn, %{"id" => id, "canonical_ingredient_id" => ingredient_id}) do
    user = conn.assigns.current_user

    case Accounts.get_avoided_ingredient(user.id, id) do
      nil ->
        {:error, :not_found}

      %{avoidance_type: "ingredient"} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Cannot add exceptions to a single ingredient avoidance"})

      avoidance ->
        case Accounts.add_avoidance_exception(avoidance, ingredient_id) do
          {:ok, updated} ->
            updated = Accounts.get_avoided_ingredient(user.id, updated.id)
            render(conn, :show, avoided_ingredient: updated)

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Removes an exception from a category or allergen avoidance.
  The ingredient will be avoided again as part of the category/allergen.
  """
  def remove_exception(conn, %{"id" => id, "canonical_ingredient_id" => ingredient_id}) do
    user = conn.assigns.current_user

    case Accounts.get_avoided_ingredient(user.id, id) do
      nil ->
        {:error, :not_found}

      %{avoidance_type: "ingredient"} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Cannot remove exceptions from a single ingredient avoidance"})

      avoidance ->
        case Accounts.remove_avoidance_exception(avoidance, ingredient_id) do
          {:ok, updated} ->
            updated = Accounts.get_avoided_ingredient(user.id, updated.id)
            render(conn, :show, avoided_ingredient: updated)

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  defp get_ingredients_for_avoidance(%{avoidance_type: "category", category: category}) do
    Ingredients.list_canonical_ingredients(category: category)
  end

  defp get_ingredients_for_avoidance(%{avoidance_type: "allergen", allergen_group: allergen_group}) do
    Ingredients.list_canonical_ingredients(allergen_group: allergen_group)
  end

  defp get_ingredients_for_avoidance(%{avoidance_type: "animal", animal_type: animal_type}) do
    Ingredients.list_canonical_ingredients(animal_type: animal_type)
  end
end
