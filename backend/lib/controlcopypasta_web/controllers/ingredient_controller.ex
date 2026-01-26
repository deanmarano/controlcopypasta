defmodule ControlcopypastaWeb.IngredientController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.CanonicalIngredient

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Lists canonical ingredients with optional filters.

  Query params:
  - is_branded: true/false - filter by branded status
  - parent_company: string - filter by parent company
  - category: string - filter by category
  - order_by: "popularity" | "name" - sort order (default: name)
  - search: string - search by name or alias
  """
  def index(conn, params) do
    filters = build_filters(params)
    ingredients = Ingredients.list_canonical_ingredients(filters)
    render(conn, :index, ingredients: ingredients)
  end

  @doc """
  Gets a canonical ingredient by ID with package sizes and nutrition.
  """
  def show(conn, %{"id" => id}) do
    case Ingredients.get_canonical_ingredient(id) do
      nil ->
        {:error, :not_found}

      ingredient ->
        package_sizes = Ingredients.list_package_sizes(id)
        nutrition = case Ingredients.get_nutrition(id) do
          {:ok, n} -> n
          {:error, :not_found} -> nil
        end
        render(conn, :show, ingredient: ingredient, package_sizes: package_sizes, nutrition: nutrition)
    end
  end

  @doc """
  Looks up a canonical ingredient by name (exact match or alias).

  POST /api/ingredients/lookup
  Body: {"name": "coca cola"}
  """
  def lookup(conn, %{"name" => name}) do
    case Ingredients.find_canonical_ingredient(name) do
      {:ok, ingredient} ->
        package_sizes = Ingredients.list_package_sizes(ingredient.id)
        nutrition = case Ingredients.get_nutrition(ingredient.id) do
          {:ok, n} -> n
          {:error, :not_found} -> nil
        end
        render(conn, :show, ingredient: ingredient, package_sizes: package_sizes, nutrition: nutrition)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ingredient not found", name: name})
    end
  end

  @doc """
  Calculates scaling suggestions with package context.

  POST /api/ingredients/scale
  Body: {
    "canonical_ingredient_id": "uuid",
    "quantity": 1,
    "unit": "can",
    "scale_factor": 2.5
  }

  Or lookup by name:
  Body: {
    "name": "coca-cola",
    "quantity": 1,
    "unit": "can",
    "scale_factor": 2.5
  }
  """
  def scale(conn, %{"canonical_ingredient_id" => id, "quantity" => qty, "unit" => unit, "scale_factor" => factor}) do
    result = Ingredients.scale_with_package_context(id, qty, unit, factor)
    render(conn, :scale_result, result: result)
  end

  def scale(conn, %{"name" => name, "quantity" => qty, "unit" => unit, "scale_factor" => factor}) do
    case Ingredients.find_canonical_ingredient(name) do
      {:ok, %CanonicalIngredient{id: id}} ->
        result = Ingredients.scale_with_package_context(id, qty, unit, factor)
        render(conn, :scale_result, result: result)

      {:error, :not_found} ->
        # No canonical match - return basic scaling without package context
        render(conn, :scale_result, result: %{
          scaled_quantity: qty * factor,
          scaled_unit: unit,
          total_volume: nil,
          package_suggestion: nil,
          available_packages: []
        })
    end
  end

  @doc """
  Bulk scaling for multiple ingredients.

  POST /api/ingredients/scale_bulk
  Body: {
    "scale_factor": 2.5,
    "ingredients": [
      {"name": "coca-cola", "quantity": 1, "unit": "can"},
      {"name": "butter", "quantity": 0.5, "unit": "cup"}
    ]
  }
  """
  def scale_bulk(conn, %{"scale_factor" => factor, "ingredients" => ingredients}) do
    results = Enum.map(ingredients, fn ing ->
      name = ing["name"]
      qty = ing["quantity"]
      unit = ing["unit"]

      case Ingredients.find_canonical_ingredient(name) do
        {:ok, %CanonicalIngredient{id: id}} ->
          result = Ingredients.scale_with_package_context(id, qty, unit, factor)
          Map.put(result, :original_name, name)

        {:error, :not_found} ->
          %{
            original_name: name,
            scaled_quantity: qty * factor,
            scaled_unit: unit,
            total_volume: nil,
            package_suggestion: nil,
            available_packages: []
          }
      end
    end)

    render(conn, :scale_bulk_result, results: results, scale_factor: factor)
  end

  @doc """
  Lists package sizes for a specific ingredient.

  GET /api/ingredients/:id/package_sizes
  """
  def package_sizes(conn, %{"id" => id}) do
    case Ingredients.get_canonical_ingredient(id) do
      nil ->
        {:error, :not_found}

      _ingredient ->
        package_sizes = Ingredients.list_package_sizes(id)
        render(conn, :package_sizes, package_sizes: package_sizes)
    end
  end

  # Build filter keyword list from params
  defp build_filters(params) do
    []
    |> maybe_add_filter(:is_branded, params["is_branded"])
    |> maybe_add_filter(:parent_company, params["parent_company"])
    |> maybe_add_filter(:category, params["category"])
    |> maybe_add_filter(:search, params["search"])
    |> maybe_add_filter(:order_by, params["order_by"])
  end

  defp maybe_add_filter(filters, _key, nil), do: filters
  defp maybe_add_filter(filters, _key, ""), do: filters
  defp maybe_add_filter(filters, :is_branded, "true"), do: [{:is_branded, true} | filters]
  defp maybe_add_filter(filters, :is_branded, "false"), do: [{:is_branded, false} | filters]
  defp maybe_add_filter(filters, :order_by, "popularity"), do: [{:order_by, :popularity} | filters]
  defp maybe_add_filter(filters, :order_by, "name"), do: [{:order_by, :name} | filters]
  defp maybe_add_filter(filters, key, value), do: [{key, value} | filters]
end
