defmodule ControlcopypastaWeb.PasskeyJSON do
  alias Controlcopypasta.Accounts.Passkey

  def index(%{passkeys: passkeys}) do
    %{data: for(passkey <- passkeys, do: data(passkey))}
  end

  def show(%{passkey: passkey}) do
    %{data: data(passkey)}
  end

  defp data(%Passkey{} = passkey) do
    %{
      id: passkey.id,
      name: passkey.name,
      transports: passkey.transports || [],
      inserted_at: passkey.inserted_at
    }
  end
end
