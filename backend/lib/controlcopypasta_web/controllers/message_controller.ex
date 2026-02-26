defmodule ControlcopypastaWeb.MessageController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Messages

  action_fallback ControlcopypastaWeb.FallbackController

  def index(conn, params) do
    user = conn.assigns.current_user

    opts = [
      limit: parse_int(params["limit"], 50),
      offset: parse_int(params["offset"], 0)
    ]

    messages = Messages.list_messages_for_user(user.id, opts)
    render(conn, :index, messages: messages)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Messages.get_message_for_user(user.id, id) do
      {:ok, message} ->
        render(conn, :show, message: message)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def save_recipe(conn, %{"message_id" => _message_id, "url_id" => url_id}) do
    user = conn.assigns.current_user

    case Messages.save_recipe_from_url(user.id, url_id) do
      {:ok, recipe} ->
        conn
        |> put_status(:created)
        |> json(%{data: %{recipe_id: recipe.id, title: recipe.title}})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :not_parsed} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "URL has not been successfully parsed yet"})

      {:error, :already_saved} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "Recipe has already been saved from this URL"})

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  defp parse_int(nil, default), do: default
  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> default
    end
  end
  defp parse_int(val, _default) when is_integer(val), do: val
  defp parse_int(_, default), do: default
end
