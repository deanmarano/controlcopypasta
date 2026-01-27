defmodule ControlcopypastaWeb.Plugs.AdminAuth do
  @moduledoc """
  Plug that verifies the current user is an admin.
  """
  import Plug.Conn

  @admin_emails ["user@example.com"]

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %{email: email} when email in @admin_emails ->
        conn

      _ ->
        conn
        |> put_status(:forbidden)
        |> Phoenix.Controller.json(%{error: "Admin access required"})
        |> halt()
    end
  end

  @doc """
  Checks if an email is an admin.
  """
  def admin?(email) when is_binary(email), do: email in @admin_emails
  def admin?(_), do: false
end
