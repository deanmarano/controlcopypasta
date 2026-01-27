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
end
