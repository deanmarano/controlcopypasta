defmodule Controlcopypasta.Accounts.ConnectedAccount do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_providers ~w(instagram tiktok)

  schema "connected_accounts" do
    field :provider, :string
    field :provider_username, :string
    field :linked_at, :utc_datetime_usec

    belongs_to :user, Controlcopypasta.Accounts.User

    timestamps()
  end

  def changeset(connected_account, attrs) do
    connected_account
    |> cast(attrs, [:user_id, :provider, :provider_username, :linked_at])
    |> validate_required([:user_id, :provider, :provider_username])
    |> validate_inclusion(:provider, @valid_providers)
    |> unique_constraint([:provider, :provider_username])
    |> foreign_key_constraint(:user_id)
  end
end
