defmodule Controlcopypasta.Accounts.Passkey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_passkeys" do
    field :credential_id, :binary
    field :public_key, :binary
    field :sign_count, :integer, default: 0
    field :name, :string, default: "Passkey"
    field :aaguid, :binary
    field :transports, {:array, :string}

    belongs_to :user, Controlcopypasta.Accounts.User

    timestamps()
  end

  def changeset(passkey, attrs) do
    passkey
    |> cast(attrs, [:credential_id, :public_key, :sign_count, :name, :aaguid, :transports, :user_id])
    |> validate_required([:credential_id, :public_key, :user_id])
    |> unique_constraint(:credential_id)
    |> foreign_key_constraint(:user_id)
  end

  def update_sign_count_changeset(passkey, sign_count) do
    passkey
    |> cast(%{sign_count: sign_count}, [:sign_count])
    |> validate_required([:sign_count])
  end
end
