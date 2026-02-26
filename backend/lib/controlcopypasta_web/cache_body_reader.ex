defmodule ControlcopypastaWeb.CacheBodyReader do
  @moduledoc """
  A custom body reader that caches the raw request body for HMAC verification.
  The raw body is stored in conn.assigns[:raw_body] as an iodata list.
  """

  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        conn = update_in(conn.assigns[:raw_body], &[&1 || [], body])
        {:ok, body, conn}

      {:more, body, conn} ->
        conn = update_in(conn.assigns[:raw_body], &[&1 || [], body])
        {:more, body, conn}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
