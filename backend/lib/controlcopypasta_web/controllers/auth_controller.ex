defmodule ControlcopypastaWeb.AuthController do
  use ControlcopypastaWeb, :controller
  require Logger

  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Accounts.{Guardian, MagicLink, Email}

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Request a magic link email.
  POST /api/auth/magic-link
  Body: {"email": "user@example.com"}
  """
  def request_magic_link(conn, %{"email" => email}) when is_binary(email) do
    # Always return success to prevent email enumeration
    email = String.trim(email) |> String.downcase()

    if valid_email?(email) do
      token = MagicLink.generate_token(email)
      base_url = get_client_base_url(conn)

      case Email.send_magic_link(email, token, base_url) do
        {:ok, _} ->
          :ok

        {:error, reason} ->
          Logger.error("Failed to send magic link email to #{email}: #{inspect(reason)}")
          :ok
      end
    end

    json(conn, %{message: "If an account exists, you will receive a magic link email."})
  end

  def request_magic_link(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Email is required"})
  end

  @doc """
  Verify a magic link token and return JWT.
  POST /api/auth/magic-link/verify
  Body: {"token": "..."}
  """
  def verify_magic_link(conn, %{"token" => token}) when is_binary(token) do
    alias ControlcopypastaWeb.Plugs.AdminAuth

    with {:ok, email} <- MagicLink.verify_token(token),
         {:ok, user} <- Accounts.get_or_create_user(email),
         {:ok, jwt, _claims} <- Guardian.encode_and_sign(user) do
      json(conn, %{
        token: jwt,
        user: %{
          id: user.id,
          email: user.email,
          is_admin: AdminAuth.admin?(user.email),
          onboarding_completed: !is_nil(user.onboarding_completed_at)
        }
      })
    else
      {:error, :expired} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Magic link has expired. Please request a new one."})

      {:error, :invalid} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid magic link."})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "An error occurred. Please try again."})
    end
  end

  def verify_magic_link(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Token is required"})
  end

  @doc """
  Refresh JWT token.
  POST /api/auth/refresh
  Header: Authorization: Bearer <token>
  """
  def refresh(conn, _params) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> old_token] ->
        with {:ok, _claims} <- Guardian.decode_and_verify(old_token),
             {:ok, _old_token, {new_token, _new_claims}} <- Guardian.refresh(old_token) do
          json(conn, %{token: new_token})
        else
          _ ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid token"})
        end

      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "No token provided"})
    end
  end

  @doc """
  Get current user info.
  GET /api/auth/me
  Header: Authorization: Bearer <token>
  """
  def me(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Not authenticated"})

      user ->
        alias ControlcopypastaWeb.Plugs.AdminAuth
        json(conn, %{
          user: %{
            id: user.id,
            email: user.email,
            inserted_at: user.inserted_at,
            is_admin: AdminAuth.admin?(user.email),
            onboarding_completed: !is_nil(user.onboarding_completed_at)
          }
        })
    end
  end

  @doc """
  Logout - client should discard token.
  POST /api/auth/logout
  """
  def logout(conn, _params) do
    # For stateless JWT, we just confirm logout
    # In production, you might want to add token blacklisting
    json(conn, %{message: "Logged out successfully"})
  end

  defp valid_email?(email) do
    String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  end

  defp get_client_base_url(conn) do
    # Try to get the base URL from Origin or Referer header
    # This ensures magic link emails use the same host the user is accessing
    case get_req_header(conn, "origin") do
      [origin] when is_binary(origin) and origin != "" ->
        origin

      _ ->
        case get_req_header(conn, "referer") do
          [referer] when is_binary(referer) and referer != "" ->
            # Extract just the origin part from referer (scheme + host + port)
            extract_origin_from_url(referer)

          _ ->
            # Fall back to constructing URL from request host (for IP-based dev access)
            build_frontend_url_from_request(conn)
        end
    end
  end

  defp extract_origin_from_url(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host, port: port}
      when is_binary(scheme) and is_binary(host) ->
        port_str = if port && port not in [80, 443], do: ":#{port}", else: ""
        "#{scheme}://#{host}#{port_str}"

      _ ->
        nil
    end
  end

  defp build_frontend_url_from_request(conn) do
    # In dev mode, derive frontend URL from the request host
    # Frontend typically runs on port 5173, backend on 4000
    host = conn.host

    if host do
      frontend_port = Application.get_env(:controlcopypasta, :frontend_port, 5173)
      scheme = if conn.scheme == :https, do: "https", else: "http"
      "#{scheme}://#{host}:#{frontend_port}"
    else
      nil
    end
  end
end
