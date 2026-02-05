defmodule Controlcopypasta.Ingredients.Preparation do
  @moduledoc """
  Schema for standard preparation methods used in recipes.

  Preparations track how ingredients are processed (diced, chopped, minced, etc.)
  separately from the ingredient itself, allowing for better recipe matching and
  understanding.

  ## Fields

  - `name` - Unique lowercase identifier (e.g., "diced")
  - `display_name` - Human-readable display name (e.g., "Diced")
  - `category` - Type of preparation (e.g., "cut", "heat", "combine")
  - `aliases` - Alternative names that mean the same thing (e.g., "cubed" -> "diced")

  ## Categories

  - `cut` - Cutting/slicing methods (diced, minced, chopped, julienned, etc.)
  - `heat` - Heat application (sauteed, roasted, grilled, etc.)
  - `temperature` - Temperature state (room temperature, chilled, frozen)
  - `texture` - Texture modifications (mashed, pureed, crushed)
  - `process` - Processing methods (drained, rinsed, strained)
  - `measure` - Measurement modifiers (packed, loosely measured, heaping)

  ## Examples

      %Preparation{
        name: "diced",
        display_name: "Diced",
        category: "cut",
        aliases: ["cubed", "cut into cubes"]
      }

      %Preparation{
        name: "room temperature",
        display_name: "Room Temperature",
        category: "temperature",
        aliases: ["at room temp", "softened"]
      }
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "preparations" do
    field :name, :string
    field :display_name, :string
    field :category, :string
    field :verb, :string
    field :metadata, :map, default: %{}
    field :aliases, {:array, :string}, default: []

    timestamps()
  end

  @required_fields [:name, :display_name]
  @optional_fields [:category, :verb, :metadata, :aliases]

  @valid_categories ~w(cut heat temperature texture process measure other)

  @doc """
  Creates a changeset for a preparation.
  """
  def changeset(preparation, attrs) do
    preparation
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:display_name, min: 1, max: 100)
    |> validate_inclusion(:category, @valid_categories ++ [nil])
    |> normalize_name()
    |> unique_constraint(:name)
  end

  defp normalize_name(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :name, String.downcase(String.trim(name)))
    end
  end

  @doc """
  Returns valid category values.
  """
  def valid_categories, do: @valid_categories
end
