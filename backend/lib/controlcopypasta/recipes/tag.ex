defmodule Controlcopypasta.Recipes.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tags" do
    field :name, :string

    many_to_many :recipes, Controlcopypasta.Recipes.Recipe, join_through: "recipe_tags"

    timestamps(updated_at: false)
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> unique_constraint(:name)
  end
end
