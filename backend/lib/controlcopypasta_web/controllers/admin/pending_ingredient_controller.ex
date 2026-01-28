defmodule ControlcopypastaWeb.Admin.PendingIngredientController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.PendingIngredientWorker

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Lists pending ingredients awaiting review.
  """
  def index(conn, params) do
    status = Map.get(params, "status", "pending")
    limit = Map.get(params, "limit", "50") |> String.to_integer()
    offset = Map.get(params, "offset", "0") |> String.to_integer()

    pending = Ingredients.list_pending_ingredients(status: status, limit: limit, offset: offset)
    stats = Ingredients.pending_ingredient_stats()

    json(conn, %{
      data: Enum.map(pending, &serialize/1),
      stats: stats,
      pagination: %{
        offset: offset,
        limit: limit,
        total: stats[String.to_atom(status)] || 0
      }
    })
  end

  @doc """
  Gets a single pending ingredient.
  """
  def show(conn, %{"id" => id}) do
    case Ingredients.get_pending_ingredient(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Pending ingredient not found"})

      pending ->
        json(conn, %{data: serialize(pending)})
    end
  end

  @doc """
  Updates a pending ingredient's suggested values.
  """
  def update(conn, %{"id" => id} = params) do
    attrs = Map.take(params, ["suggested_display_name", "suggested_category", "suggested_aliases"])
    attrs = for {k, v} <- attrs, into: %{}, do: {String.to_atom(k), v}

    case Ingredients.update_pending_ingredient(id, attrs) do
      {:ok, pending} ->
        json(conn, %{data: serialize(pending)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  @doc """
  Approves a pending ingredient, creating a new canonical.
  """
  def approve(conn, %{"id" => id} = params) do
    user_id = conn.assigns[:current_user] && conn.assigns.current_user.id

    attrs = %{
      display_name: params["display_name"],
      category: params["category"],
      aliases: params["aliases"] || []
    }

    case Ingredients.approve_pending_ingredient(id, attrs, user_id) do
      {:ok, canonical} ->
        json(conn, %{
          message: "Approved and created canonical ingredient",
          data: %{
            id: canonical.id,
            name: canonical.name,
            display_name: canonical.display_name
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
    end
  end

  @doc """
  Rejects a pending ingredient.
  """
  def reject(conn, %{"id" => id}) do
    user_id = conn.assigns[:current_user] && conn.assigns.current_user.id

    case Ingredients.reject_pending_ingredient(id, user_id) do
      {:ok, pending} ->
        json(conn, %{message: "Rejected", data: serialize(pending)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  @doc """
  Merges a pending ingredient into an existing canonical as an alias.
  """
  def merge(conn, %{"id" => id, "canonical_id" => canonical_id}) do
    user_id = conn.assigns[:current_user] && conn.assigns.current_user.id

    case Ingredients.merge_pending_ingredient(id, canonical_id, user_id) do
      {:ok, canonical} ->
        json(conn, %{
          message: "Merged as alias",
          data: %{
            id: canonical.id,
            name: canonical.name,
            aliases: canonical.aliases
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
    end
  end

  @doc """
  Triggers a scan for new pending ingredients.
  Clears existing pending ingredients before re-scanning.
  """
  def scan(conn, _params) do
    # Clear existing pending ingredients before re-scanning
    {:ok, cleared_count} = Ingredients.clear_pending_ingredients()

    case PendingIngredientWorker.enqueue() do
      {:ok, job} ->
        json(conn, %{
          message: "Cleared #{cleared_count} pending ingredients, scan job enqueued",
          job_id: job.id,
          cleared_count: cleared_count
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
    end
  end

  @doc """
  Gets pending ingredient statistics.
  """
  def stats(conn, _params) do
    stats = Ingredients.pending_ingredient_stats()
    json(conn, %{data: stats})
  end

  defp serialize(pending) do
    %{
      id: pending.id,
      name: pending.name,
      occurrence_count: pending.occurrence_count,
      sample_texts: pending.sample_texts,
      status: pending.status,
      fatsecret_id: pending.fatsecret_id,
      fatsecret_name: pending.fatsecret_name,
      suggested_display_name: pending.suggested_display_name,
      suggested_category: pending.suggested_category,
      suggested_aliases: pending.suggested_aliases,
      reviewed_at: pending.reviewed_at,
      inserted_at: pending.inserted_at
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
