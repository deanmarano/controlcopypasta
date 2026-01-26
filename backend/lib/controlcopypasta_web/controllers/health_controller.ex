defmodule ControlcopypastaWeb.HealthController do
  use ControlcopypastaWeb, :controller

  def index(conn, _params) do
    # Check database connection
    case Ecto.Adapters.SQL.query(Controlcopypasta.Repo, "SELECT 1") do
      {:ok, _} ->
        json(conn, %{status: "ok", database: "connected"})

      {:error, _} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error", database: "disconnected"})
    end
  end
end
