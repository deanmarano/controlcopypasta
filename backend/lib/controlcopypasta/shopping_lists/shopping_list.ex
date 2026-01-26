defmodule Controlcopypasta.ShoppingLists.ShoppingList do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shopping_lists" do
    field :name, :string
    field :archived_at, :utc_datetime

    belongs_to :user, Controlcopypasta.Accounts.User
    has_many :items, Controlcopypasta.ShoppingLists.ShoppingListItem

    timestamps()
  end

  @required_fields [:name, :user_id]
  @optional_fields [:archived_at]

  def changeset(shopping_list, attrs) do
    shopping_list
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, max: 255)
  end
end
