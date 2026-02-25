defmodule ControlcopypastaWeb.ConnectedAccountJSON do
  alias Controlcopypasta.Accounts.ConnectedAccount

  def index(%{connected_accounts: accounts}) do
    %{data: for(account <- accounts, do: data(account))}
  end

  def show(%{connected_account: account}) do
    %{data: data(account)}
  end

  defp data(%ConnectedAccount{} = account) do
    %{
      id: account.id,
      provider: account.provider,
      provider_username: account.provider_username,
      linked_at: account.linked_at,
      inserted_at: account.inserted_at
    }
  end
end
