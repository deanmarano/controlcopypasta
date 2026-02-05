defmodule ControlcopypastaWeb.Admin.PreparationController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.Preparation

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Lists preparations with optional filters.

  Query params:
  - category: filter by category
  - search: search by name
  """
  def index(conn, params) do
    filters = build_filters(params)
    preparations = Ingredients.list_preparations(filters)
    render(conn, :index, preparations: preparations)
  end

  @doc """
  Gets a single preparation.
  """
  def show(conn, %{"id" => id}) do
    case Ingredients.get_preparation(id) do
      nil ->
        {:error, :not_found}

      preparation ->
        render(conn, :show, preparation: preparation)
    end
  end

  @doc """
  Creates a new preparation and refreshes the parser cache.
  """
  def create(conn, %{"preparation" => attrs}) do
    case Ingredients.create_preparation(attrs) do
      {:ok, preparation} ->
        Ingredients.refresh_parser_cache!()

        conn
        |> put_status(:created)
        |> render(:show, preparation: preparation)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a preparation and refreshes the parser cache.
  """
  def update(conn, %{"id" => id, "preparation" => attrs}) do
    case Ingredients.get_preparation(id) do
      nil ->
        {:error, :not_found}

      preparation ->
        case Ingredients.update_preparation(preparation, attrs) do
          {:ok, updated} ->
            Ingredients.refresh_parser_cache!()
            render(conn, :show, preparation: updated)

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Deletes a preparation and refreshes the parser cache.
  """
  def delete(conn, %{"id" => id}) do
    case Ingredients.get_preparation(id) do
      nil ->
        {:error, :not_found}

      preparation ->
        case Ingredients.delete_preparation(preparation) do
          {:ok, _} ->
            Ingredients.refresh_parser_cache!()
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
    render(conn, :options, categories: Preparation.valid_categories())
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
