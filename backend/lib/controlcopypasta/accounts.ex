defmodule Controlcopypasta.Accounts do
  @moduledoc """
  The Accounts context for user management and authentication.
  """

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Accounts.{User, AvoidedIngredient, Passkey}
  alias Controlcopypasta.Ingredients

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
    |> preload(:canonical_ingredient)
    |> Repo.all()
  end

  def get_avoided_ingredient(user_id, id) do
    AvoidedIngredient
    |> where([a], a.user_id == ^user_id and a.id == ^id)
    |> preload(:canonical_ingredient)
    |> Repo.one()
  end

  @doc """
  Creates an avoided ingredient (text-based matching).
  This is the legacy method that normalizes display_name to canonical_name.
  """
  def create_avoided_ingredient(user_id, attrs) do
    attrs = Map.put(attrs, "user_id", user_id)
    attrs = Map.put_new(attrs, "avoidance_type", "ingredient")

    %AvoidedIngredient{}
    |> AvoidedIngredient.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an avoided ingredient by canonical ingredient ID (precise matching).
  """
  def create_avoided_ingredient_by_canonical(user_id, canonical_ingredient_id, display_name) do
    attrs = %{
      "user_id" => user_id,
      "avoidance_type" => "ingredient",
      "canonical_ingredient_id" => canonical_ingredient_id,
      "display_name" => display_name
    }

    %AvoidedIngredient{}
    |> AvoidedIngredient.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an avoided category (e.g., "dairy", "protein").
  All ingredients in this category will be avoided.
  """
  def create_avoided_category(user_id, category) do
    display_name = category |> String.replace("_", " ") |> String.capitalize()

    attrs = %{
      "user_id" => user_id,
      "avoidance_type" => "category",
      "category" => category,
      "display_name" => display_name
    }

    %AvoidedIngredient{}
    |> AvoidedIngredient.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an avoided allergen group (e.g., "shellfish", "tree_nuts").
  All ingredients in this allergen group will be avoided.
  """
  def create_avoided_allergen_group(user_id, allergen_group) do
    display_name = allergen_group |> String.replace("_", " ") |> String.capitalize()

    attrs = %{
      "user_id" => user_id,
      "avoidance_type" => "allergen",
      "allergen_group" => allergen_group,
      "display_name" => display_name
    }

    %AvoidedIngredient{}
    |> AvoidedIngredient.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an avoided animal type (e.g., "chicken", "beef", "pork").
  All ingredients of this animal type will be avoided.
  """
  def create_avoided_animal_type(user_id, animal_type) do
    display_name = animal_type |> String.replace("_", " ") |> String.capitalize()

    attrs = %{
      "user_id" => user_id,
      "avoidance_type" => "animal",
      "animal_type" => animal_type,
      "display_name" => display_name
    }

    %AvoidedIngredient{}
    |> AvoidedIngredient.changeset(attrs)
    |> Repo.insert()
  end

  def delete_avoided_ingredient(%AvoidedIngredient{} = avoided_ingredient) do
    Repo.delete(avoided_ingredient)
  end

  @doc """
  Adds an exception to a category or allergen avoidance.
  The exception is a canonical_ingredient_id that should be allowed despite the avoidance.
  """
  def add_avoidance_exception(%AvoidedIngredient{} = avoidance, canonical_ingredient_id) do
    current_exceptions = avoidance.exceptions || []

    if canonical_ingredient_id in current_exceptions do
      {:ok, avoidance}
    else
      avoidance
      |> AvoidedIngredient.changeset(%{exceptions: [canonical_ingredient_id | current_exceptions]})
      |> Repo.update()
    end
  end

  @doc """
  Removes an exception from a category or allergen avoidance.
  """
  def remove_avoidance_exception(%AvoidedIngredient{} = avoidance, canonical_ingredient_id) do
    current_exceptions = avoidance.exceptions || []
    new_exceptions = Enum.reject(current_exceptions, &(&1 == canonical_ingredient_id))

    avoidance
    |> AvoidedIngredient.changeset(%{exceptions: new_exceptions})
    |> Repo.update()
  end

  @doc """
  Gets all avoided canonical names (legacy text-based matching).
  """
  def get_avoided_canonical_names(user_id) do
    AvoidedIngredient
    |> where([a], a.user_id == ^user_id and a.avoidance_type == "ingredient")
    |> where([a], not is_nil(a.canonical_name))
    |> select([a], a.canonical_name)
    |> Repo.all()
    |> MapSet.new()
  end

  @doc """
  Gets all avoided canonical ingredient IDs, expanding categories, allergen groups, and animal types.

  Returns a MapSet of canonical ingredient IDs that should be avoided.
  This includes:
  - Directly avoided ingredient IDs
  - All ingredient IDs in avoided categories (minus exceptions)
  - All ingredient IDs in avoided allergen groups (minus exceptions)
  - All ingredient IDs of avoided animal types (minus exceptions)

  For text-based avoidances without canonical_ingredient_id, they are not included
  in this result (use get_avoided_canonical_names for those).
  """
  def get_avoided_canonical_ids(user_id) do
    avoidances = list_avoided_ingredients(user_id)

    # Separate by type
    {ingredient_avoidances, category_avoidances, allergen_avoidances, animal_avoidances} =
      Enum.reduce(avoidances, {[], [], [], []}, fn a, {ing, cat, all, ani} ->
        case a.avoidance_type do
          "ingredient" -> {[a | ing], cat, all, ani}
          "category" -> {ing, [a | cat], all, ani}
          "allergen" -> {ing, cat, [a | all], ani}
          "animal" -> {ing, cat, all, [a | ani]}
          _ -> {ing, cat, all, ani}
        end
      end)

    # Get direct ingredient IDs
    direct_ids =
      ingredient_avoidances
      |> Enum.map(& &1.canonical_ingredient_id)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    # Get IDs from categories (with exceptions removed)
    category_ids =
      if Enum.empty?(category_avoidances) do
        MapSet.new()
      else
        Enum.reduce(category_avoidances, MapSet.new(), fn avoidance, acc ->
          category_ingredient_ids = Ingredients.list_canonical_ids_by_categories([avoidance.category])
          exceptions = MapSet.new(avoidance.exceptions || [])
          filtered_ids = MapSet.difference(category_ingredient_ids, exceptions)
          MapSet.union(acc, filtered_ids)
        end)
      end

    # Get IDs from allergen groups (with exceptions removed)
    allergen_ids =
      if Enum.empty?(allergen_avoidances) do
        MapSet.new()
      else
        Enum.reduce(allergen_avoidances, MapSet.new(), fn avoidance, acc ->
          allergen_ingredient_ids = Ingredients.list_canonical_ids_by_allergen_groups([avoidance.allergen_group])
          exceptions = MapSet.new(avoidance.exceptions || [])
          filtered_ids = MapSet.difference(allergen_ingredient_ids, exceptions)
          MapSet.union(acc, filtered_ids)
        end)
      end

    # Get IDs from animal types (with exceptions removed)
    animal_ids =
      if Enum.empty?(animal_avoidances) do
        MapSet.new()
      else
        Enum.reduce(animal_avoidances, MapSet.new(), fn avoidance, acc ->
          animal_ingredient_ids = Ingredients.list_canonical_ids_by_animal_types([avoidance.animal_type])
          exceptions = MapSet.new(avoidance.exceptions || [])
          filtered_ids = MapSet.difference(animal_ingredient_ids, exceptions)
          MapSet.union(acc, filtered_ids)
        end)
      end

    # Combine all
    direct_ids
    |> MapSet.union(category_ids)
    |> MapSet.union(allergen_ids)
    |> MapSet.union(animal_ids)
  end

  # Onboarding

  @doc """
  Marks the user's onboarding as complete.
  """
  def complete_onboarding(%User{} = user) do
    user
    |> User.preferences_changeset(%{onboarding_completed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Creates multiple avoided ingredients in a single transaction.
  Skips duplicates (constraint errors).
  """
  def create_avoided_ingredients_bulk(user_id, avoidance_list) when is_list(avoidance_list) do
    Repo.transaction(fn ->
      Enum.map(avoidance_list, fn avoidance ->
        result =
          case Map.get(avoidance, "type") do
            "allergen" ->
              create_avoided_allergen_group(user_id, Map.get(avoidance, "value"))

            "animal" ->
              create_avoided_animal_type(user_id, Map.get(avoidance, "value"))

            "category" ->
              create_avoided_category(user_id, Map.get(avoidance, "value"))

            "ingredient" ->
              create_avoided_ingredient(user_id, %{"display_name" => Map.get(avoidance, "value")})

            _ ->
              {:error, :invalid_type}
          end

        case result do
          {:ok, record} -> record
          # Skip duplicates
          {:error, %Ecto.Changeset{errors: [{_, {_, [constraint: :unique, constraint_name: _]}} | _]}} -> nil
          {:error, _} -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end)
  end

  # User Preferences

  @doc """
  Updates user preferences.
  """
  def update_user_preferences(%User{} = user, attrs) do
    user
    |> User.preferences_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets user preferences.
  """
  def get_user_preferences(%User{} = user) do
    %{
      hide_avoided_ingredients: user.hide_avoided_ingredients,
      onboarding_completed: !is_nil(user.onboarding_completed_at)
    }
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
