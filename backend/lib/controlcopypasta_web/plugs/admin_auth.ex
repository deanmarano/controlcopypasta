defmodule ControlcopypastaWeb.Plugs.AdminAuth do
  @moduledoc """
  Plug that verifies the current user is an admin.

  Admin emails are configured via the ADMIN_EMAILS environment variable
  (comma-separated list).
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %{email: email} ->
        if admin?(email) do
          conn
        else
          forbidden(conn)
        end

      _ ->
        forbidden(conn)
    end
  end

  @doc """
  Checks if an email is an admin.
  """
  def admin?(email) when is_binary(email), do: email in admin_emails()
  def admin?(_), do: false

  defp admin_emails do
    Application.get_env(:controlcopypasta, :admin_emails, [])
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> Phoenix.Controller.json(%{error: "Admin access required"})
    |> halt()
  end
end
