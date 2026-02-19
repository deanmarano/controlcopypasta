defmodule Controlcopypasta.Quicklist.AvoidedCache do
  @moduledoc """
  ETS-based cache for per-user avoided ingredient params.
  Avoidance preferences rarely change, so we cache them with a 5-minute TTL
  to avoid recomputing on every quicklist batch request.
  """

  use GenServer

  @table __MODULE__
  @ttl_ms :timer.minutes(5)

  # Public API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Returns cached avoided params for the user, computing from DB on cache miss.
  """
  def get_avoided_params(user) do
    case lookup(user.id) do
      {:ok, params} ->
        params

      :miss ->
        params = compute_avoided_params(user)
        insert(user.id, params)
        params
    end
  end

  @doc """
  Invalidates the cache entry for a user (call when avoidance preferences change).
  """
  def invalidate(user_id) do
    :ets.delete(@table, user_id)
    :ok
  end

  # GenServer callbacks

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    {:ok, %{}}
  end

  # Private helpers

  defp lookup(user_id) do
    case :ets.lookup(@table, user_id) do
      [{^user_id, params, inserted_at}] ->
        if System.monotonic_time(:millisecond) - inserted_at < @ttl_ms do
          {:ok, params}
        else
          :ets.delete(@table, user_id)
          :miss
        end

      [] ->
        :miss
    end
  end

  defp insert(user_id, params) do
    :ets.insert(@table, {user_id, params, System.monotonic_time(:millisecond)})
  end

  defp compute_avoided_params(user) do
    if user.hide_avoided_ingredients do
      avoided_ids = Controlcopypasta.Accounts.get_avoided_canonical_ids(user.id)

      if MapSet.size(avoided_ids) > 0 do
        avoided_names =
          Controlcopypasta.Ingredients.list_canonical_names_by_ids(avoided_ids)

        %{
          "exclude_ingredient_ids" => MapSet.to_list(avoided_ids),
          "exclude_ingredient_names" => avoided_names
        }
      else
        %{}
      end
    else
      %{}
    end
  end
end
