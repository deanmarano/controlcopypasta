defmodule Controlcopypasta.Accounts do
  @moduledoc """
  The Accounts context for user management and authentication.
  """

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Accounts.{User, AvoidedIngredient, Passkey}

  def get_user(id), do: Repo.get(User, id)

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_or_create_user(email) when is_binary(email) do
    email = String.downcase(email)

    case get_user_by_email(email) do
      nil -> create_user(%{email: email})
      user -> {:ok, user}
    end
  end

  # Avoided Ingredients

  def list_avoided_ingredients(user_id) do
    AvoidedIngredient
    |> where([a], a.user_id == ^user_id)
    |> order_by(:display_name)
    |> Repo.all()
  end

  def get_avoided_ingredient(user_id, id) do
    AvoidedIngredient
    |> where([a], a.user_id == ^user_id and a.id == ^id)
    |> Repo.one()
  end

  def create_avoided_ingredient(user_id, attrs) do
    %AvoidedIngredient{}
    |> AvoidedIngredient.changeset(Map.put(attrs, "user_id", user_id))
    |> Repo.insert()
  end

  def delete_avoided_ingredient(%AvoidedIngredient{} = avoided_ingredient) do
    Repo.delete(avoided_ingredient)
  end

  def get_avoided_canonical_names(user_id) do
    AvoidedIngredient
    |> where([a], a.user_id == ^user_id)
    |> select([a], a.canonical_name)
    |> Repo.all()
    |> MapSet.new()
  end

  # Passkeys

  def list_passkeys(user_id) do
    Passkey
    |> where([p], p.user_id == ^user_id)
    |> order_by(:inserted_at)
    |> Repo.all()
  end

  def get_passkey(user_id, id) do
    Passkey
    |> where([p], p.user_id == ^user_id and p.id == ^id)
    |> Repo.one()
  end

  def get_passkey_by_credential_id(credential_id) when is_binary(credential_id) do
    Passkey
    |> where([p], p.credential_id == ^credential_id)
    |> Repo.one()
    |> Repo.preload(:user)
  end

  def create_passkey(user, attrs) do
    %Passkey{}
    |> Passkey.changeset(Map.put(attrs, :user_id, user.id))
    |> Repo.insert()
  end

  def update_passkey_sign_count(%Passkey{} = passkey, sign_count) do
    passkey
    |> Passkey.update_sign_count_changeset(sign_count)
    |> Repo.update()
  end

  def delete_passkey(%Passkey{} = passkey) do
    Repo.delete(passkey)
  end

  def count_passkeys(user_id) do
    Passkey
    |> where([p], p.user_id == ^user_id)
    |> Repo.aggregate(:count, :id)
  end
end
