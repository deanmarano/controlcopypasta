defmodule Controlcopypasta.Recipes.IngredientDecision do
  @moduledoc """
  Stores user decisions for alternative ingredients in their saved recipes.

  When a recipe has ingredients with alternatives (e.g., "1 cup avocado oil or coconut oil"),
  users can select which option they prefer. These decisions are stored per-user and applied
  when calculating nutrition information.

  ## Example

      # User selects coconut oil instead of avocado oil for ingredient at index 2
      %IngredientDecision{
        recipe_id: "recipe-uuid",
        user_id: "user-uuid",
        ingredient_index: 2,
        selected_canonical_id: "coconut-oil-uuid",
        selected_name: "coconut oil"
      }
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ingredient_decisions" do
    belongs_to :recipe, Recipe
    belongs_to :user, User

    field :ingredient_index, :integer
    field :selected_canonical_id, :binary_id
    field :selected_name, :string

    timestamps()
  end

  @required_fields [:recipe_id, :user_id, :ingredient_index, :selected_canonical_id]
  @optional_fields [:selected_name]

  @doc """
  Creates a changeset for an ingredient decision.
  """
  def changeset(decision, attrs) do
    decision
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:ingredient_index, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:recipe_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:recipe_id, :user_id, :ingredient_index],
      name: :ingredient_decisions_recipe_id_user_id_ingredient_index_index,
      message: "decision already exists for this ingredient"
    )
  end
end
