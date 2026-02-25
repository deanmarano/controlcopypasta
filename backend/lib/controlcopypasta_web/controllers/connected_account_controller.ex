defmodule ControlcopypastaWeb.ConnectedAccountController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Accounts

  action_fallback ControlcopypastaWeb.FallbackController

  def index(conn, _params) do
    user = conn.assigns.current_user
    accounts = Accounts.list_connected_accounts(user.id)
    render(conn, :index, connected_accounts: accounts)
  end

  def link(conn, %{"provider" => provider, "username" => username, "token" => token}) do
    user = conn.assigns.current_user

    case Accounts.link_account(user.id, provider, username, token) do
      {:ok, account} ->
        conn
        |> put_status(:created)
        |> render(:show, connected_account: account)

      {:error, :invalid_token} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or expired linking token"})

      {:error, :linking_not_configured} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Account linking is not configured"})

      {:error, %Ecto.Changeset{} = changeset} ->
        if has_unique_constraint_error?(changeset) do
          conn
          |> put_status(:conflict)
          |> json(%{error: "This social account is already linked"})
        else
          {:error, changeset}
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.unlink_account(user.id, id) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Connected account not found"})
    end
  end

  defp has_unique_constraint_error?(changeset) do
    Enum.any?(changeset.errors, fn {_field, {_msg, opts}} ->
      Keyword.get(opts, :constraint) == :unique
    end)
  end
end
