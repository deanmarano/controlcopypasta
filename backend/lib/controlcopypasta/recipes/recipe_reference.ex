defmodule Controlcopypasta.Recipes.RecipeReference do
  @moduledoc """
  Represents a reference from one recipe to another (sub-recipe or component).

  Many recipes reference other recipes within their ingredients:
  - "1 cup Homemade Marinara Sauce (see recipe below)"
  - "2 cups chicken stock (recipe follows)"
  - "1/2 cup pesto, homemade or store-bought"

  This schema tracks these references and links them to their resolved child recipes
  when available.

  ## Reference Types

  - `:below` - "see recipe below", "recipe follows"
  - `:above` - "see recipe above", "recipe from above"
  - `:notes` - "see notes", "in notes"
  - `:link` - Contains URL to another recipe
  - `:inline` - "homemade recipe", mentioned inline

  ## Example

      %RecipeReference{
        parent_recipe_id: "main-dish-uuid",
        child_recipe_id: "sauce-uuid",  # May be nil if not yet resolved
        ingredient_index: 3,
        reference_type: "below",
        reference_text: "see recipe below",
        extracted_name: "marinara sauce",
        is_optional: false
      }
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Controlcopypasta.Recipes.Recipe

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @reference_types ~w(below above notes link inline)

  schema "recipe_references" do
    belongs_to :parent_recipe, Recipe
    belongs_to :child_recipe, Recipe

    field :ingredient_index, :integer
    field :reference_type, :string
    field :reference_text, :string
    field :extracted_name, :string
    field :resolved_at, :utc_datetime
    field :is_optional, :boolean, default: false

    timestamps()
  end

  @required_fields [:parent_recipe_id, :ingredient_index, :reference_type]
  @optional_fields [:child_recipe_id, :reference_text, :extracted_name, :resolved_at, :is_optional]

  @doc """
  Creates a changeset for a recipe reference.
  """
  def changeset(reference, attrs) do
    reference
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:reference_type, @reference_types)
    |> validate_number(:ingredient_index, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:parent_recipe_id)
    |> foreign_key_constraint(:child_recipe_id)
    |> unique_constraint([:parent_recipe_id, :ingredient_index],
      name: :recipe_references_parent_recipe_id_ingredient_index_index,
      message: "reference already exists for this ingredient"
    )
  end

  @doc """
  Marks the reference as resolved with a child recipe.
  """
  def resolve_changeset(reference, child_recipe_id) do
    reference
    |> change(%{
      child_recipe_id: child_recipe_id,
      resolved_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end
end
