defmodule ControlcopypastaWeb.Admin.KitchenToolController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.KitchenTool

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Lists kitchen tools with optional filters.

  Query params:
  - category: filter by category
  - search: search by name
  """
  def index(conn, params) do
    filters = build_filters(params)
    kitchen_tools = Ingredients.list_kitchen_tools(filters)
    render(conn, :index, kitchen_tools: kitchen_tools)
  end

  @doc """
  Gets a single kitchen tool.
  """
  def show(conn, %{"id" => id}) do
    case Ingredients.get_kitchen_tool(id) do
      nil ->
        {:error, :not_found}

      kitchen_tool ->
        render(conn, :show, kitchen_tool: kitchen_tool)
    end
  end

  @doc """
  Creates a new kitchen tool.
  """
  def create(conn, %{"kitchen_tool" => attrs}) do
    case Ingredients.create_kitchen_tool(attrs) do
      {:ok, kitchen_tool} ->
        conn
        |> put_status(:created)
        |> render(:show, kitchen_tool: kitchen_tool)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a kitchen tool.
  """
  def update(conn, %{"id" => id, "kitchen_tool" => attrs}) do
    case Ingredients.get_kitchen_tool(id) do
      nil ->
        {:error, :not_found}

      kitchen_tool ->
        case Ingredients.update_kitchen_tool(kitchen_tool, attrs) do
          {:ok, updated} ->
            render(conn, :show, kitchen_tool: updated)

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Deletes a kitchen tool.
  """
  def delete(conn, %{"id" => id}) do
    case Ingredients.get_kitchen_tool(id) do
      nil ->
        {:error, :not_found}

      kitchen_tool ->
        case Ingredients.delete_kitchen_tool(kitchen_tool) do
          {:ok, _} ->
            send_resp(conn, :no_content, "")

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Returns options for admin forms (valid categories).
  """
  def options(conn, _params) do
    render(conn, :options, categories: KitchenTool.valid_categories())
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
      if params["search"] && params["search"] != "" do
        [{:search, params["search"]} | filters]
      else
        filters
      end

    [{:order_by, :name} | filters]
  end
end
