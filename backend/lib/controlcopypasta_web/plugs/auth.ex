defmodule ControlcopypastaWeb.Plugs.Auth do
  @moduledoc """
  Authentication plugs for API endpoints.
  """

  import Plug.Conn
  alias Controlcopypasta.Accounts.Guardian

  def init(opts), do: opts

  @doc """
  Authenticates the user from the Authorization header.
  Sets conn.assigns.current_user if valid.
  """
  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      assign(conn, :current_user, user)
    else
      _ -> assign(conn, :current_user, nil)
    end
  end

  @doc """
  Ensures a user is authenticated. Returns 401 if not.
  Use after the Auth plug in a pipeline.
  """
  def require_auth(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.put_view(json: ControlcopypastaWeb.ErrorJSON)
        |> Phoenix.Controller.render(:"401")
        |> halt()

      _user ->
        conn
    end
  end
end
