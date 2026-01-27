defmodule Controlcopypasta.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :hide_avoided_ingredients, :boolean, default: false

    has_many :recipes, Controlcopypasta.Recipes.Recipe
    has_many :avoided_ingredients, Controlcopypasta.Accounts.AvoidedIngredient
    has_many :passkeys, Controlcopypasta.Accounts.Passkey

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 255)
    |> unique_constraint(:email)
    |> downcase_email()
  end

  defp downcase_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, String.downcase(email))
    end
  end

  @doc """
  Creates a changeset for updating user preferences.
  """
  def preferences_changeset(user, attrs) do
    user
    |> cast(attrs, [:hide_avoided_ingredients])
  end
end
