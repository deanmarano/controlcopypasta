defmodule Controlcopypasta.Ingredients.PendingIngredient do
  @moduledoc """
  Schema for pending ingredient records awaiting admin review.

  These are ingredients extracted from recipes that don't match any canonical
  ingredient. They're queued for review when they appear frequently enough.

  ## Status values

  - `pending` - Awaiting admin review
  - `approved` - Approved and converted to canonical ingredient
  - `rejected` - Rejected (not a real ingredient, parsing error, etc.)
  - `merged` - Merged into an existing canonical as an alias
  - `tool` - Marked as a kitchen tool/utensil (not a real ingredient)
  - `preparation` - Marked as a preparation method (not a real ingredient)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pending_ingredients" do
    field :name, :string
    field :occurrence_count, :integer, default: 1
    field :sample_texts, {:array, :string}, default: []
    field :status, :string, default: "pending"

    # FatSecret data
    field :fatsecret_id, :string
    field :fatsecret_name, :string
    field :fatsecret_data, :map

    # Suggested values
    field :suggested_display_name, :string
    field :suggested_category, :string
    field :suggested_aliases, {:array, :string}, default: []

    # Review tracking
    field :reviewed_at, :utc_datetime

    belongs_to :merged_into, Controlcopypasta.Ingredients.CanonicalIngredient
    belongs_to :reviewed_by, Controlcopypasta.Accounts.User

    timestamps()
  end

  @valid_statuses ~w(pending approved rejected merged tool preparation)
  @valid_categories Controlcopypasta.Ingredients.CanonicalIngredient.valid_categories()

  def changeset(pending, attrs) do
    pending
    |> cast(attrs, [
      :name,
      :occurrence_count,
      :sample_texts,
      :status,
      :fatsecret_id,
      :fatsecret_name,
      :fatsecret_data,
      :suggested_display_name,
      :suggested_category,
      :suggested_aliases,
      :merged_into_id,
      :reviewed_at,
      :reviewed_by_id
    ])
    |> validate_required([:name])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:suggested_category, @valid_categories ++ [nil])
    |> normalize_name()
    |> unique_constraint(:name)
  end

  defp normalize_name(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :name, String.downcase(String.trim(name)))
    end
  end
end
