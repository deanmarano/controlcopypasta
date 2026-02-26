defmodule ControlcopypastaWeb.Plugs.BotAuth do
  @moduledoc """
  Authenticates bot requests using HMAC-SHA256 signature verification.
  Expects the `X-Bot-Signature` header containing a base64url-encoded
  HMAC of the raw request body using the ACCOUNT_LINKING_SECRET.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    secret = Application.get_env(:controlcopypasta, :account_linking_secret)

    if is_nil(secret) or secret == "" do
      conn
      |> put_status(:internal_server_error)
      |> Phoenix.Controller.json(%{error: "Bot authentication is not configured"})
      |> halt()
    else
      verify_signature(conn, secret)
    end
  end

  defp verify_signature(conn, secret) do
    with [signature] <- get_req_header(conn, "x-bot-signature"),
         raw_body when is_list(raw_body) <- conn.assigns[:raw_body],
         body = IO.iodata_to_binary(raw_body),
         expected = :crypto.mac(:hmac, :sha256, secret, body) |> Base.url_encode64(padding: false),
         true <- Plug.Crypto.secure_compare(expected, signature) do
      conn
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Invalid bot signature"})
        |> halt()
    end
  end
end
