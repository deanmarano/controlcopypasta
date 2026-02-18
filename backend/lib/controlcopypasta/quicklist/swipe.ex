defmodule Controlcopypasta.Quicklist.Swipe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "quicklist_swipes" do
    field :action, :string

    belongs_to :user, Controlcopypasta.Accounts.User
    belongs_to :recipe, Controlcopypasta.Recipes.Recipe

    timestamps()
  end

  @valid_actions ~w(maybe skip)

  def changeset(swipe, attrs) do
    swipe
    |> cast(attrs, [:user_id, :recipe_id, :action])
    |> validate_required([:user_id, :recipe_id, :action])
    |> validate_inclusion(:action, @valid_actions)
    |> unique_constraint([:user_id, :recipe_id])
  end
end
