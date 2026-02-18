defmodule ControlcopypastaWeb.PasskeyController do
  use ControlcopypastaWeb, :controller
  require Logger

  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Accounts.Guardian

  action_fallback ControlcopypastaWeb.FallbackController

  # Challenge token TTL: 5 minutes
  @challenge_ttl 300

  defp webauthn_config do
    Application.get_env(:controlcopypasta, :webauthn)
  end

  defp sign_challenge(challenge, user_id \\ nil) do
    # Serialize the full Wax.Challenge struct
    data = %{
      challenge: :erlang.term_to_binary(challenge) |> Base.encode64(),
      user_id: user_id
    }
    Phoenix.Token.sign(ControlcopypastaWeb.Endpoint, "webauthn_challenge", data)
  end

  defp verify_challenge_token(token) do
    case Phoenix.Token.verify(ControlcopypastaWeb.Endpoint, "webauthn_challenge", token, max_age: @challenge_ttl) do
      {:ok, data} ->
        challenge = data.challenge |> Base.decode64!() |> :erlang.binary_to_term()
        {:ok, challenge, data.user_id}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generate registration options for a new passkey.
  POST /api/auth/passkeys/register/options
  Requires authentication.
  """
  def register_options(conn, _params) do
    user = conn.assigns.current_user
    config = webauthn_config()

    # Create the Wax challenge with registration options
    challenge = Wax.new_registration_challenge(
      origin: config[:origin],
      rp_id: config[:rp_id],
      attestation: "none"
    )

    challenge_token = sign_challenge(challenge, user.id)

    # Get existing credentials to exclude
    existing_passkeys = Accounts.list_passkeys(user.id)
    exclude_credentials = Enum.map(existing_passkeys, fn passkey ->
      %{
        id: Base.url_encode64(passkey.credential_id, padding: false),
        type: "public-key",
        transports: passkey.transports || []
      }
    end)

    options = %{
      challenge: Base.url_encode64(challenge.bytes, padding: false),
      rp: %{
        name: config[:rp_name],
        id: config[:rp_id]
      },
      user: %{
        id: Base.url_encode64(user.id, padding: false),
        name: user.email,
        displayName: user.email
      },
      pubKeyCredParams: [
        %{alg: -7, type: "public-key"},   # ES256
        %{alg: -257, type: "public-key"}  # RS256
      ],
      timeout: 60000,
      attestation: "none",
      excludeCredentials: exclude_credentials,
      authenticatorSelection: %{
        residentKey: "preferred",
        userVerification: "preferred"
      },
      challengeToken: challenge_token
    }

    Logger.info("Passkey registration options: #{inspect(options, limit: :infinity)}")
    json(conn, options)
  end

  @doc """
  Complete passkey registration.
  POST /api/auth/passkeys/register
  Requires authentication.
  """
  def register(conn, params) do
    user = conn.assigns.current_user
    user_id = user.id

    with {:ok, challenge, ^user_id} <- verify_challenge_token(params["challengeToken"]),
         {:ok, {auth_data, _attestation_result}} <- verify_attestation(params, challenge) do

      credential_id = auth_data.attested_credential_data.credential_id
      cose_key = auth_data.attested_credential_data.credential_public_key
      aaguid = auth_data.attested_credential_data.aaguid

      # Serialize COSE key to binary
      cose_key_binary = :erlang.term_to_binary(cose_key)

      passkey_attrs = %{
        credential_id: credential_id,
        public_key: cose_key_binary,
        sign_count: auth_data.sign_count,
        name: params["name"] || "Passkey",
        aaguid: aaguid,
        transports: params["transports"] || []
      }

      case Accounts.create_passkey(user, passkey_attrs) do
        {:ok, passkey} ->
          conn
          |> put_status(:created)
          |> render(:show, passkey: passkey)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> put_view(json: ControlcopypastaWeb.ChangesetJSON)
          |> render(:error, changeset: changeset)
      end
    else
      {:error, :expired} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Challenge expired. Please try again."})

      {:error, :invalid} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid challenge token."})

      {:error, reason} ->
        Logger.error("Passkey registration failed: #{inspect(reason)}")
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Registration failed: #{inspect(reason)}"})

      other ->
        Logger.error("Passkey registration unexpected result: #{inspect(other)}")
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid registration data."})
    end
  rescue
    e ->
      Logger.error("Passkey registration exception: #{Exception.message(e)}")
      Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
      conn
      |> put_status(:internal_server_error)
      |> json(%{error: "Internal error during passkey registration"})
  end

  defp verify_attestation(params, challenge) do
    response = params["response"]

    if is_nil(response) or is_nil(response["clientDataJSON"]) or is_nil(response["attestationObject"]) do
      {:error, :missing_response_data}
    else
      try do
        # SimpleWebAuthn sends data as base64url encoded without padding
        client_data_json = Base.url_decode64!(response["clientDataJSON"], padding: false)
        attestation_object = Base.url_decode64!(response["attestationObject"], padding: false)

        Wax.register(attestation_object, client_data_json, challenge)
      rescue
        e ->
          Logger.error("Passkey registration error: #{inspect(e)}")
          {:error, {:decode_error, Exception.message(e)}}
      end
    end
  end

  @doc """
  Generate authentication options.
  POST /api/auth/passkeys/authenticate/options
  Public endpoint - requires email to find user's credentials.
  """
  def authenticate_options(conn, %{"email" => email}) when is_binary(email) do
    config = webauthn_config()
    email = String.trim(email) |> String.downcase()

    # Get user's passkeys if they exist
    {allow_credentials, allow_credentials_for_challenge} =
      case Accounts.get_user_by_email(email) do
        nil ->
          {[], []}
        user ->
          passkeys = Accounts.list_passkeys(user.id)

          # Format for frontend (base64url encoded)
          frontend_creds = Enum.map(passkeys, fn passkey ->
            %{
              id: Base.url_encode64(passkey.credential_id, padding: false),
              type: "public-key",
              transports: passkey.transports || []
            }
          end)

          # Format for Wax challenge (binary credential_id + cose_key)
          wax_creds = Enum.map(passkeys, fn passkey ->
            cose_key = :erlang.binary_to_term(passkey.public_key)
            {passkey.credential_id, cose_key}
          end)

          {frontend_creds, wax_creds}
      end

    # Create the Wax challenge with authentication options
    challenge = Wax.new_authentication_challenge(
      origin: config[:origin],
      rp_id: config[:rp_id],
      allow_credentials: allow_credentials_for_challenge
    )

    challenge_token = sign_challenge(challenge)

    options = %{
      challenge: Base.url_encode64(challenge.bytes, padding: false),
      timeout: 60000,
      rpId: config[:rp_id],
      allowCredentials: allow_credentials,
      userVerification: "preferred",
      challengeToken: challenge_token
    }

    json(conn, options)
  end

  def authenticate_options(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Email is required"})
  end

  @doc """
  Complete passkey authentication.
  POST /api/auth/passkeys/authenticate
  Public endpoint.
  """
  def authenticate(conn, params) do
    with {:ok, challenge, _} <- verify_challenge_token(params["challengeToken"]),
         {:ok, passkey, auth_data} <- verify_assertion(params, challenge),
         {:ok, _} <- Accounts.update_passkey_sign_count(passkey, auth_data.sign_count),
         {:ok, jwt, _claims} <- Guardian.encode_and_sign(passkey.user) do

      alias ControlcopypastaWeb.Plugs.AdminAuth

      json(conn, %{
        token: jwt,
        user: %{
          id: passkey.user.id,
          email: passkey.user.email,
          is_admin: AdminAuth.admin?(passkey.user.email),
          onboarding_completed: !is_nil(passkey.user.onboarding_completed_at)
        }
      })
    else
      {:error, :expired} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Challenge expired. Please try again."})

      {:error, :invalid} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid authentication."})

      {:error, :passkey_not_found} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Passkey not recognized."})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication failed: #{inspect(reason)}"})
    end
  end

  defp verify_assertion(params, challenge) do
    credential_id = Base.url_decode64!(params["id"], padding: false)

    case Accounts.get_passkey_by_credential_id(credential_id) do
      nil ->
        {:error, :passkey_not_found}

      passkey ->
        # SimpleWebAuthn sends data as base64url encoded without padding
        client_data_json = Base.url_decode64!(params["response"]["clientDataJSON"], padding: false)
        authenticator_data = Base.url_decode64!(params["response"]["authenticatorData"], padding: false)
        signature = Base.url_decode64!(params["response"]["signature"], padding: false)

        case Wax.authenticate(
          credential_id,
          authenticator_data,
          signature,
          client_data_json,
          challenge
        ) do
          {:ok, auth_data} ->
            {:ok, passkey, auth_data}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  List user's passkeys.
  GET /api/auth/passkeys
  Requires authentication.
  """
  def index(conn, _params) do
    user = conn.assigns.current_user
    passkeys = Accounts.list_passkeys(user.id)
    render(conn, :index, passkeys: passkeys)
  end

  @doc """
  Delete a passkey.
  DELETE /api/auth/passkeys/:id
  Requires authentication.
  """
  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.get_passkey(user.id, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Passkey not found"})

      passkey ->
        case Accounts.delete_passkey(passkey) do
          {:ok, _} ->
            send_resp(conn, :no_content, "")

          {:error, _} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Failed to delete passkey"})
        end
    end
  end
end
