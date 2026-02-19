defmodule ControlcopypastaWeb.QuicklistController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Quicklist
  alias Controlcopypasta.Quicklist.AvoidedCache

  action_fallback ControlcopypastaWeb.FallbackController

  def batch(conn, params) do
    user = conn.assigns.current_user
    count = Map.get(params, "count", "10") |> parse_int(10) |> min(30)
    tag = Map.get(params, "tag")
    avoided_params = AvoidedCache.get_avoided_params(user)

    recipes = Quicklist.get_swipe_batch(user.id, count, avoided_params, tag)
    render(conn, :batch, recipes: recipes, user_id: user.id)
  end

  def maybe_list(conn, _params) do
    user = conn.assigns.current_user
    recipes = Quicklist.list_maybe_recipes(user.id)
    render(conn, :maybe_list, recipes: recipes, user_id: user.id)
  end

  def swipe(conn, %{"recipe_id" => recipe_id, "action" => action}) do
    user = conn.assigns.current_user

    case Quicklist.record_swipe(user.id, recipe_id, action) do
      {:ok, swipe} ->
        conn
        |> put_status(:created)
        |> json(%{data: %{id: swipe.id, action: swipe.action, recipe_id: swipe.recipe_id}})

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def remove_maybe(conn, %{"recipe_id" => recipe_id}) do
    user = conn.assigns.current_user
    :ok = Quicklist.remove_from_maybe(user.id, recipe_id)
    send_resp(conn, :no_content, "")
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
