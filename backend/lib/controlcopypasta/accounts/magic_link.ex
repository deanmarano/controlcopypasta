defmodule Controlcopypasta.Accounts.MagicLink do
  @moduledoc """
  Magic link token generation and verification using Phoenix.Token.
  """

  @token_salt "magic_link_salt"
  @token_max_age 600  # 10 minutes

  def generate_token(email) when is_binary(email) do
    Phoenix.Token.sign(ControlcopypastaWeb.Endpoint, @token_salt, email)
  end

  def verify_token(token) when is_binary(token) do
    case Phoenix.Token.verify(ControlcopypastaWeb.Endpoint, @token_salt, token, max_age: @token_max_age) do
      {:ok, email} -> {:ok, email}
      {:error, :expired} -> {:error, :expired}
      {:error, :invalid} -> {:error, :invalid}
    end
  end
end
