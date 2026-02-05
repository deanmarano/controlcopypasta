defmodule Controlcopypasta.Ingredients.KitchenTool do
  @moduledoc """
  Schema for kitchen tools and equipment referenced by preparations.

  Kitchen tools track physical tools needed for recipe preparation (knife, grater,
  whisk, etc.) separately from preparation methods, allowing for better equipment
  planning and shopping.

  ## Fields

  - `name` - Unique lowercase identifier (e.g., "knife")
  - `display_name` - Human-readable display name (e.g., "Knife")
  - `category` - Type of tool (e.g., "cutting", "mixing", "processing")
  - `aliases` - Alternative names (e.g., "chef's knife", "paring knife")
  - `metadata` - Optional additional data

  ## Categories

  - `cutting` - Cutting/slicing tools (knife, grater, peeler, mandoline, zester)
  - `mixing` - Mixing/stirring tools (whisk, stand mixer)
  - `processing` - Processing tools (blender, food processor, sifter, masher)
  - `measuring` - Measuring tools (thermometer, measuring cup)
  - `baking` - Baking tools (baking sheet, rolling pin)
  - `cooking` - Cooking tools/vessels (spatula, tongs, dutch oven, skewer)
  - `other` - Uncategorized tools
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "kitchen_tools" do
    field :name, :string
    field :display_name, :string
    field :category, :string
    field :aliases, {:array, :string}, default: []
    field :metadata, :map, default: %{}

    timestamps()
  end

  @required_fields [:name, :display_name]
  @optional_fields [:category, :metadata, :aliases]

  @valid_categories ~w(cutting mixing processing measuring baking cooking other)

  @doc """
  Creates a changeset for a kitchen tool.
  """
  def changeset(kitchen_tool, attrs) do
    kitchen_tool
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
