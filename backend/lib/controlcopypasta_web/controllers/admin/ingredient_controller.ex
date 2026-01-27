defmodule ControlcopypastaWeb.Admin.IngredientController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.CanonicalIngredient

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Lists ingredients with admin-focused filters.

  Query params:
  - category: filter by category
  - animal_type: filter by animal_type
  - missing_animal_type: "true" to show only protein ingredients without animal_type
  - search: search by name
  """
  def index(conn, params) do
    filters = build_filters(params)
    ingredients = Ingredients.list_canonical_ingredients(filters)
    render(conn, :index, ingredients: ingredients)
  end

  @doc """
  Updates an ingredient's admin-editable fields.
  """
  def update(conn, %{"id" => id, "ingredient" => attrs}) do
    case Ingredients.get_canonical_ingredient(id) do
      nil ->
        {:error, :not_found}

      ingredient ->
        # Only allow updating certain fields via admin
        allowed_attrs = Map.take(attrs, ["animal_type", "category", "subcategory", "tags"])

        case Ingredients.update_canonical_ingredient(ingredient, allowed_attrs) do
          {:ok, updated} ->
            render(conn, :show, ingredient: updated)

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Returns options for admin forms (valid categories, animal types, etc.)
  """
  def options(conn, _params) do
    render(conn, :options,
      categories: CanonicalIngredient.valid_categories(),
      animal_types: CanonicalIngredient.valid_animal_types()
    )
  end

  defp build_filters(params) do
    filters = []

    filters =
      if params["category"] && params["category"] != "" do
        [{:category, params["category"]} | filters]
      else
        filters
      end

    filters =
      if params["animal_type"] && params["animal_type"] != "" do
        [{:animal_type, params["animal_type"]} | filters]
      else
        filters
      end

    filters =
      if params["search"] && params["search"] != "" do
        [{:search, params["search"]} | filters]
      else
        filters
      end

    filters =
      if params["missing_animal_type"] == "true" do
        [{:missing_animal_type, true} | filters]
      else
        filters
      end

    # Default ordering
    [{:order_by, :name} | filters]
  end
end
