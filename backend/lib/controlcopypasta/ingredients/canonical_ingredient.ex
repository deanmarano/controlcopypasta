defmodule Controlcopypasta.Ingredients.CanonicalIngredient do
  @moduledoc """
  Schema for canonical ingredient records in the ingredient catalog.

  Canonical ingredients represent the normalized, standard form of an ingredient
  (e.g., "tomato" rather than "Roma tomato", "cherry tomatoes", etc.).

  ## Fields

  - `name` - Unique lowercase identifier (e.g., "chicken breast")
  - `display_name` - Human-readable display name (e.g., "Chicken Breast")
  - `category` - Top-level category (e.g., "protein", "dairy", "produce")
  - `subcategory` - More specific grouping (e.g., "poultry", "leafy greens")
  - `tags` - Searchable tags for grouping related ingredients (e.g., ["meat", "chicken"])
  - `is_allergen` - Whether this ingredient is a common allergen
  - `allergen_groups` - Which allergen categories this belongs to (e.g., ["dairy", "lactose"])
  - `dietary_flags` - Dietary compatibility flags (e.g., ["vegetarian", "gluten-free"])
  - `aliases` - Alternative names that should match to this ingredient

  ## Examples

      %CanonicalIngredient{
        name: "chicken breast",
        display_name: "Chicken Breast",
        category: "protein",
        subcategory: "poultry",
        tags: ["meat", "chicken", "white meat"],
        dietary_flags: ["gluten-free", "dairy-free"]
      }

      %CanonicalIngredient{
        name: "milk",
        display_name: "Milk",
        category: "dairy",
        is_allergen: true,
        allergen_groups: ["dairy", "lactose"],
        dietary_flags: ["vegetarian", "gluten-free"]
      }
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "canonical_ingredients" do
    field :name, :string
    field :display_name, :string

    # Category tags (flat, searchable)
    field :category, :string
    field :subcategory, :string
    field :tags, {:array, :string}, default: []

    # Allergen tracking
    field :is_allergen, :boolean, default: false
    field :allergen_groups, {:array, :string}, default: []

    # Dietary info
    field :dietary_flags, {:array, :string}, default: []

    # Matching
    field :aliases, {:array, :string}, default: []

    # Branding
    field :brand, :string
    field :parent_company, :string
    field :is_branded, :boolean, default: false

    # Media
    field :image_url, :string

    # Usage statistics (cached, updated periodically)
    field :usage_count, :integer, default: 0

    has_many :forms, Controlcopypasta.Ingredients.IngredientForm
    has_many :package_sizes, Controlcopypasta.Ingredients.BrandPackageSize

    timestamps()
  end

  @required_fields [:name, :display_name]
  @optional_fields [
    :category,
    :subcategory,
    :tags,
    :is_allergen,
    :allergen_groups,
    :dietary_flags,
    :aliases,
    :brand,
    :parent_company,
    :is_branded,
    :image_url
  ]

  @valid_categories ~w(protein dairy produce grain spice herb condiment oil sweetener leavening nut legume beverage other)
  @valid_allergen_groups ~w(dairy eggs peanuts tree_nuts wheat gluten soy fish shellfish sesame)
  @valid_dietary_flags ~w(vegetarian vegan gluten_free dairy_free keto paleo)

  @doc """
  Creates a changeset for a canonical ingredient.
  """
  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:display_name, min: 1, max: 255)
    |> validate_inclusion(:category, @valid_categories ++ [nil])
    |> validate_array_subset(:allergen_groups, @valid_allergen_groups)
    |> validate_array_subset(:dietary_flags, @valid_dietary_flags)
    |> normalize_name()
    |> unique_constraint(:name)
  end

  defp normalize_name(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :name, String.downcase(String.trim(name)))
    end
  end

  defp validate_array_subset(changeset, field, allowed_values) do
    validate_change(changeset, field, fn _, values ->
      invalid = Enum.reject(values, &(&1 in allowed_values))

      if Enum.empty?(invalid) do
        []
      else
        [{field, "contains invalid values: #{Enum.join(invalid, ", ")}"}]
      end
    end)
  end

  @doc """
  Returns valid category values.
  """
  def valid_categories, do: @valid_categories

  @doc """
  Returns valid allergen group values.
  """
  def valid_allergen_groups, do: @valid_allergen_groups

  @doc """
  Returns valid dietary flag values.
  """
  def valid_dietary_flags, do: @valid_dietary_flags
end
