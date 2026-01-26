defmodule Controlcopypasta.ShoppingLists.ShoppingListItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shopping_list_items" do
    field :display_text, :string
    field :quantity, :decimal
    field :unit, :string
    field :canonical_name, :string
    field :raw_name, :string
    field :category, :string, default: "other"
    field :checked_at, :utc_datetime
    field :notes, :string
    field :source_recipe_ids, {:array, :binary_id}, default: []

    belongs_to :shopping_list, Controlcopypasta.ShoppingLists.ShoppingList
    belongs_to :canonical_ingredient, Controlcopypasta.Ingredients.CanonicalIngredient

    timestamps()
  end

  @required_fields [:display_text, :shopping_list_id]
  @optional_fields [
    :quantity,
    :unit,
    :canonical_ingredient_id,
    :canonical_name,
    :raw_name,
    :category,
    :checked_at,
    :notes,
    :source_recipe_ids
  ]

  @valid_categories [
    "produce",
    "dairy",
    "protein",
    "bakery",
    "pantry",
    "frozen",
    "beverages",
    "condiments",
    "spices",
    "other"
  ]

  def changeset(item, attrs) do
    item
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:display_text, max: 500)
    |> validate_length(:unit, max: 50)
    |> validate_inclusion(:category, @valid_categories)
  end

  def check_changeset(item) do
    change(item, checked_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def uncheck_changeset(item) do
    change(item, checked_at: nil)
  end
end
