defmodule Controlcopypasta.Accounts.AvoidedIngredient do
  use Ecto.Schema
  import Ecto.Changeset
  alias Controlcopypasta.Similarity.IngredientNormalizer
  alias Controlcopypasta.Ingredients.CanonicalIngredient

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @avoidance_types ~w(ingredient category allergen animal)
  @valid_categories CanonicalIngredient.valid_categories()
  @valid_allergen_groups CanonicalIngredient.valid_allergen_groups()
  @valid_animal_types CanonicalIngredient.valid_animal_types()

  schema "avoided_ingredients" do
    field :canonical_name, :string
    field :display_name, :string
    field :avoidance_type, :string, default: "ingredient"
    field :category, :string
    field :allergen_group, :string
    field :animal_type, :string
    # Exceptions: canonical_ingredient_ids that are allowed despite the category/allergen avoidance
    field :exceptions, {:array, :binary_id}, default: []

    belongs_to :user, Controlcopypasta.Accounts.User
    belongs_to :canonical_ingredient, Controlcopypasta.Ingredients.CanonicalIngredient

    timestamps(updated_at: false)
  end

  @doc """
  Returns the list of valid avoidance types.
  """
  def avoidance_types, do: @avoidance_types

  @doc """
  Returns the list of valid categories for category-based avoidance.
  """
  def valid_categories, do: @valid_categories

  @doc """
  Returns the list of valid allergen groups for allergen-based avoidance.
  """
  def valid_allergen_groups, do: @valid_allergen_groups

  @doc """
  Returns the list of valid animal types for animal-based avoidance.
  """
  def valid_animal_types, do: @valid_animal_types

  @doc """
  Creates a changeset for an avoided ingredient.
  """
  def changeset(avoided_ingredient, attrs) do
    avoided_ingredient
    |> cast(attrs, [
      :display_name,
      :user_id,
      :canonical_ingredient_id,
      :avoidance_type,
      :category,
      :allergen_group,
      :animal_type,
      :exceptions
    ])
    |> validate_required([:display_name, :user_id, :avoidance_type])
    |> validate_length(:display_name, min: 1, max: 255)
    |> validate_inclusion(:avoidance_type, @avoidance_types)
    |> validate_avoidance_type_fields()
    |> maybe_normalize_ingredient()
    |> add_unique_constraints()
  end

  # Validates that the correct fields are set based on avoidance_type
  defp validate_avoidance_type_fields(changeset) do
    case get_field(changeset, :avoidance_type) do
      "ingredient" ->
        changeset
        |> validate_ingredient_fields()

      "category" ->
        changeset
        |> validate_required([:category], message: "is required for category avoidance")
        |> validate_inclusion(:category, @valid_categories,
          message: "must be a valid category"
        )

      "allergen" ->
        changeset
        |> validate_required([:allergen_group], message: "is required for allergen avoidance")
        |> validate_inclusion(:allergen_group, @valid_allergen_groups,
          message: "must be a valid allergen group"
        )

      "animal" ->
        changeset
        |> validate_required([:animal_type], message: "is required for animal avoidance")
        |> validate_inclusion(:animal_type, @valid_animal_types,
          message: "must be a valid animal type"
        )

      _ ->
        changeset
    end
  end

  # For ingredient avoidance, either canonical_ingredient_id or text-based matching is required
  defp validate_ingredient_fields(changeset) do
    # Text-based ingredient avoidance doesn't require canonical_ingredient_id
    # It will use the display_name normalized to canonical_name
    changeset
  end

  # Only normalize ingredient name for text-based ingredient avoidances
  defp maybe_normalize_ingredient(changeset) do
    avoidance_type = get_field(changeset, :avoidance_type)
    canonical_id = get_field(changeset, :canonical_ingredient_id)

    if avoidance_type == "ingredient" && is_nil(canonical_id) do
      case get_change(changeset, :display_name) do
        nil -> changeset
        name -> put_change(changeset, :canonical_name, IngredientNormalizer.normalize(name))
      end
    else
      changeset
    end
  end

  # Adds unique constraints based on avoidance type
  defp add_unique_constraints(changeset) do
    case get_field(changeset, :avoidance_type) do
      "ingredient" ->
        changeset
        |> unique_constraint([:user_id, :canonical_ingredient_id],
          name: :avoided_ingredients_user_ingredient_idx,
          message: "ingredient already in your avoided list"
        )
        |> unique_constraint([:user_id, :canonical_name],
          name: :avoided_ingredients_user_canonical_name_idx,
          message: "ingredient already in your avoided list"
        )

      "category" ->
        changeset
        |> unique_constraint([:user_id, :category],
          name: :avoided_ingredients_user_category_idx,
          message: "category already in your avoided list"
        )

      "allergen" ->
        changeset
        |> unique_constraint([:user_id, :allergen_group],
          name: :avoided_ingredients_user_allergen_idx,
          message: "allergen group already in your avoided list"
        )

      "animal" ->
        changeset
        |> unique_constraint([:user_id, :animal_type],
          name: :avoided_ingredients_user_animal_idx,
          message: "animal type already in your avoided list"
        )

      _ ->
        changeset
    end
  end
end
