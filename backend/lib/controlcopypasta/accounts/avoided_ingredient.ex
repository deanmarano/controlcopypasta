defmodule Controlcopypasta.Accounts.AvoidedIngredient do
  use Ecto.Schema
  import Ecto.Changeset
  alias Controlcopypasta.Similarity.IngredientNormalizer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "avoided_ingredients" do
    field :canonical_name, :string
    field :display_name, :string

    belongs_to :user, Controlcopypasta.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(avoided_ingredient, attrs) do
    avoided_ingredient
    |> cast(attrs, [:display_name, :user_id])
    |> validate_required([:display_name, :user_id])
    |> validate_length(:display_name, min: 1, max: 255)
    |> normalize_ingredient()
    |> unique_constraint([:user_id, :canonical_name],
      message: "ingredient already in your avoided list"
    )
  end

  defp normalize_ingredient(changeset) do
    case get_change(changeset, :display_name) do
      nil -> changeset
      name -> put_change(changeset, :canonical_name, IngredientNormalizer.normalize(name))
    end
  end
end
