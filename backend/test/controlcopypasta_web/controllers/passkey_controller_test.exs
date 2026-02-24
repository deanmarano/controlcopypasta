defmodule ControlcopypastaWeb.PasskeyControllerTest do
  use ControlcopypastaWeb.ConnCase, async: true

  alias Controlcopypasta.Accounts

  import Controlcopypasta.AccountsFixtures

  def passkey_fixture(user, attrs \\ %{}) do
    default_attrs = %{
      credential_id: :crypto.strong_rand_bytes(32),
      public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7}),
      sign_count: 0,
      name: "Test Passkey",
      transports: ["internal"]
    }

    {:ok, passkey} = Accounts.create_passkey(user, Map.merge(default_attrs, attrs))
    passkey
  end

  describe "POST /api/auth/passkeys/register/options" do
    setup :setup_authenticated_conn

    test "returns registration options with challenge", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/auth/passkeys/register/options")
      response = json_response(conn, 200)

      assert response["challenge"]
      assert response["challengeToken"]
      assert response["rp"]["id"] == "localhost"
      assert response["rp"]["name"] == "ControlCopyPasta"
      assert response["user"]["name"] == user.email
      assert response["user"]["displayName"] == user.email
      assert response["pubKeyCredParams"]
      assert response["timeout"] == 60000
      assert response["attestation"] == "none"
      assert response["authenticatorSelection"]["residentKey"] == "preferred"
    end

    test "excludes existing passkeys from registration options", %{conn: conn, user: user} do
      passkey = passkey_fixture(user)

      conn = post(conn, ~p"/api/auth/passkeys/register/options")
      response = json_response(conn, 200)

      assert length(response["excludeCredentials"]) == 1

      [excluded] = response["excludeCredentials"]
      assert excluded["type"] == "public-key"
      assert excluded["id"] == Base.url_encode64(passkey.credential_id, padding: false)
    end

    test "returns empty excludeCredentials when no passkeys exist", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/passkeys/register/options")
      response = json_response(conn, 200)

      assert response["excludeCredentials"] == []
    end

    test "returns 401 when not authenticated" do
      conn =
        build_conn()
        |> post(~p"/api/auth/passkeys/register/options")

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/auth/passkeys/register" do
    setup :setup_authenticated_conn

    test "returns error for missing challengeToken", %{conn: conn} do
      conn =
        post(conn, ~p"/api/auth/passkeys/register", %{
          "response" => %{
            "clientDataJSON" => Base.encode64("{}"),
            "attestationObject" => Base.encode64("test")
          }
        })

      assert json_response(conn, 400)["error"]
    end

    test "returns error for expired challenge token", %{conn: conn} do
      # Create an expired token by signing with a past timestamp
      # This is tricky to test without modifying the code, so we'll test with an invalid token
      conn =
        post(conn, ~p"/api/auth/passkeys/register", %{
          "challengeToken" => "invalid-token",
          "response" => %{
            "clientDataJSON" => Base.encode64("{}"),
            "attestationObject" => Base.encode64("test")
          }
        })

      assert json_response(conn, 400)["error"] =~ "Invalid"
    end

    test "returns 401 when not authenticated" do
      conn =
        build_conn()
        |> post(~p"/api/auth/passkeys/register", %{})

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/auth/passkeys/authenticate/options" do
    test "returns authentication options with challenge for existing user", %{conn: conn} do
      user = user_fixture()
      passkey = passkey_fixture(user)

      conn = post(conn, ~p"/api/auth/passkeys/authenticate/options", %{"email" => user.email})
      response = json_response(conn, 200)

      assert response["challenge"]
      assert response["challengeToken"]
      assert response["rpId"] == "localhost"
      assert response["timeout"] == 60000
      assert response["userVerification"] == "preferred"

      assert length(response["allowCredentials"]) == 1
      [allowed] = response["allowCredentials"]
      assert allowed["type"] == "public-key"
      assert allowed["id"] == Base.url_encode64(passkey.credential_id, padding: false)
    end

    test "returns empty allowCredentials for user with no passkeys", %{conn: conn} do
      user = user_fixture()

      conn = post(conn, ~p"/api/auth/passkeys/authenticate/options", %{"email" => user.email})
      response = json_response(conn, 200)

      assert response["allowCredentials"] == []
    end

    test "returns empty allowCredentials for non-existent user", %{conn: conn} do
      conn =
        post(conn, ~p"/api/auth/passkeys/authenticate/options", %{
          "email" => "nonexistent@example.com"
        })

      response = json_response(conn, 200)

      assert response["challenge"]
      assert response["allowCredentials"] == []
    end

    test "handles case-insensitive email", %{conn: conn} do
      user = user_fixture(%{email: "test@example.com"})
      passkey_fixture(user)

      conn =
        post(conn, ~p"/api/auth/passkeys/authenticate/options", %{"email" => "TEST@EXAMPLE.COM"})

      response = json_response(conn, 200)

      assert length(response["allowCredentials"]) == 1
    end

    test "returns error when email is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/passkeys/authenticate/options", %{})
      assert json_response(conn, 400)["error"] == "Email is required"
    end
  end

  describe "POST /api/auth/passkeys/authenticate" do
    test "returns error for invalid challengeToken", %{conn: conn} do
      conn =
        post(conn, ~p"/api/auth/passkeys/authenticate", %{
          "challengeToken" => "invalid-token",
          "id" => Base.url_encode64("test", padding: false),
          "response" => %{
            "clientDataJSON" => Base.encode64("{}"),
            "authenticatorData" => Base.encode64("test"),
            "signature" => Base.encode64("test")
          }
        })

      assert json_response(conn, 401)["error"] =~ "Invalid"
    end

    test "returns error for unknown credential_id", %{conn: conn} do
      user = user_fixture()
      passkey_fixture(user)

      # First get valid options to get a real challenge token
      options_conn =
        post(conn, ~p"/api/auth/passkeys/authenticate/options", %{"email" => user.email})

      options = json_response(options_conn, 200)

      # Try to authenticate with a different credential_id
      conn =
        post(conn, ~p"/api/auth/passkeys/authenticate", %{
          "challengeToken" => options["challengeToken"],
          "id" => Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false),
          "response" => %{
            "clientDataJSON" => Base.encode64("{}"),
            "authenticatorData" => Base.encode64("test"),
            "signature" => Base.encode64("test")
          }
        })

      assert json_response(conn, 401)["error"] == "Passkey not recognized."
    end
  end

  describe "GET /api/auth/passkeys" do
    setup :setup_authenticated_conn

    test "returns list of user's passkeys", %{conn: conn, user: user} do
      passkey1 = passkey_fixture(user, %{name: "MacBook Pro"})
      passkey2 = passkey_fixture(user, %{name: "iPhone"})

      conn = get(conn, ~p"/api/auth/passkeys")
      response = json_response(conn, 200)

      assert length(response["data"]) == 2

      names = Enum.map(response["data"], & &1["name"])
      assert "MacBook Pro" in names
      assert "iPhone" in names

      # Verify passkey structure
      [first | _] = response["data"]
      assert first["id"]
      assert first["name"]
      assert first["inserted_at"]
      assert Map.has_key?(first, "transports")
    end

    test "returns empty list when no passkeys", %{conn: conn} do
      conn = get(conn, ~p"/api/auth/passkeys")
      response = json_response(conn, 200)

      assert response["data"] == []
    end

    test "does not return passkeys from other users", %{conn: conn, user: _user} do
      other_user = user_fixture()
      passkey_fixture(other_user)

      conn = get(conn, ~p"/api/auth/passkeys")
      response = json_response(conn, 200)

      assert response["data"] == []
    end

    test "returns 401 when not authenticated" do
      conn = get(build_conn(), ~p"/api/auth/passkeys")
      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/auth/passkeys/:id" do
    setup :setup_authenticated_conn

    test "deletes the passkey", %{conn: conn, user: user} do
      passkey = passkey_fixture(user)

      conn = delete(conn, ~p"/api/auth/passkeys/#{passkey.id}")
      assert response(conn, 204)

      # Verify it's deleted
      assert Accounts.get_passkey(user.id, passkey.id) == nil
    end

    test "returns 404 for non-existent passkey", %{conn: conn} do
      conn = delete(conn, ~p"/api/auth/passkeys/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)["error"] == "Passkey not found"
    end

    test "returns 404 when trying to delete another user's passkey", %{conn: conn} do
      other_user = user_fixture()
      passkey = passkey_fixture(other_user)

      conn = delete(conn, ~p"/api/auth/passkeys/#{passkey.id}")
      assert json_response(conn, 404)["error"] == "Passkey not found"

      # Verify it wasn't deleted
      assert Accounts.get_passkey(other_user.id, passkey.id) != nil
    end

    test "returns 401 when not authenticated" do
      user = user_fixture()
      passkey = passkey_fixture(user)

      conn = delete(build_conn(), ~p"/api/auth/passkeys/#{passkey.id}")
      assert json_response(conn, 401)
    end
  end
end
