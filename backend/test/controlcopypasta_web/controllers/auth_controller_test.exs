defmodule ControlcopypastaWeb.AuthControllerTest do
  use ControlcopypastaWeb.ConnCase, async: true

  alias Controlcopypasta.Accounts.MagicLink

  import Controlcopypasta.AccountsFixtures

  describe "POST /api/auth/magic-link" do
    test "returns success message for valid email", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/magic-link", %{email: "test@example.com"})

      assert json_response(conn, 200)["message"] ==
               "If an account exists, you will receive a magic link email."
    end

    test "returns success message even for invalid email format (prevents enumeration)", %{
      conn: conn
    } do
      conn = post(conn, ~p"/api/auth/magic-link", %{email: "invalid"})

      assert json_response(conn, 200)["message"] ==
               "If an account exists, you will receive a magic link email."
    end

    test "returns error when email is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/magic-link", %{})
      assert json_response(conn, 400)["error"] == "Email is required"
    end

    test "trims and lowercases email", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/magic-link", %{email: "  TEST@Example.COM  "})
      assert json_response(conn, 200)["message"] =~ "magic link"
    end
  end

  describe "POST /api/auth/magic-link/verify" do
    test "returns JWT token for valid magic link", %{conn: conn} do
      email = "verify@example.com"
      token = MagicLink.generate_token(email)

      conn = post(conn, ~p"/api/auth/magic-link/verify", %{token: token})
      response = json_response(conn, 200)

      assert response["token"]
      assert response["user"]["email"] == email
    end

    test "creates user if doesn't exist", %{conn: conn} do
      email = "newuser#{System.unique_integer()}@example.com"
      token = MagicLink.generate_token(email)

      conn = post(conn, ~p"/api/auth/magic-link/verify", %{token: token})
      response = json_response(conn, 200)

      assert response["user"]["email"] == email
      assert Controlcopypasta.Accounts.get_user_by_email(email)
    end

    test "returns existing user if already exists", %{conn: conn} do
      user = user_fixture()
      token = MagicLink.generate_token(user.email)

      conn = post(conn, ~p"/api/auth/magic-link/verify", %{token: token})
      response = json_response(conn, 200)

      assert response["user"]["id"] == user.id
    end

    test "returns error for invalid token", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/magic-link/verify", %{token: "invalid-token"})

      assert json_response(conn, 401)["error"] == "Invalid magic link."
    end

    test "returns error when token is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/magic-link/verify", %{})
      assert json_response(conn, 400)["error"] == "Token is required"
    end
  end

  describe "POST /api/auth/refresh" do
    test "returns new token for valid existing token", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = Controlcopypasta.Accounts.Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/auth/refresh")

      response = json_response(conn, 200)
      assert response["token"]
      assert response["token"] != token
    end

    test "returns error for invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid-token")
        |> post(~p"/api/auth/refresh")

      assert json_response(conn, 401)["error"] == "Invalid token"
    end

    test "returns error when no token provided", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/refresh")
      assert json_response(conn, 401)["error"] == "No token provided"
    end
  end

  describe "GET /api/auth/me" do
    setup :setup_authenticated_conn

    test "returns current user info when authenticated", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/auth/me")
      response = json_response(conn, 200)

      assert response["user"]["id"] == user.id
      assert response["user"]["email"] == user.email
    end

    test "returns error when not authenticated", %{conn: _conn} do
      conn =
        build_conn()
        |> get(~p"/api/auth/me")

      assert json_response(conn, 401)["error"] == "Not authenticated"
    end
  end

  describe "POST /api/auth/logout" do
    test "returns success message", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/logout")
      assert json_response(conn, 200)["message"] == "Logged out successfully"
    end
  end
end
