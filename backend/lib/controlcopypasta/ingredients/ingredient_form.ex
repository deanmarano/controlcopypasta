defmodule Controlcopypasta.Ingredients.IngredientForm do
  @moduledoc """
  Schema for ingredient forms (canned, frozen, dried, etc.).

  Forms track different product variations of a canonical ingredient, including
  their typical packaging sizes and units.

  ## Fields

  - `canonical_ingredient_id` - Reference to the parent canonical ingredient
  - `form_name` - Name of this form (e.g., "canned", "frozen", "dried")
  - `default_unit` - Typical unit for this form (e.g., "can", "package")
  - `default_size_value` - Standard container size (e.g., 14.5 for a 14.5 oz can)
  - `default_size_unit` - Unit for the size (e.g., "oz", "g")

  ## Examples

      # 14.5 oz canned tomatoes
      %IngredientForm{
        canonical_ingredient_id: tomato_id,
        form_name: "canned",
        default_unit: "can",
        default_size_value: Decimal.new("14.5"),
        default_size_unit: "oz"
      }

      # Frozen chicken breast (typically sold by weight)
      %IngredientForm{
        canonical_ingredient_id: chicken_breast_id,
        form_name: "frozen",
        default_unit: "lb",
        default_size_value: nil,
        default_size_unit: nil
      }

      # Dried pasta (16 oz box)
      %IngredientForm{
        canonical_ingredient_id: pasta_id,
        form_name: "dried",
        default_unit: "box",
        default_size_value: Decimal.new("16"),
        default_size_unit: "oz"
      }
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ingredient_forms" do
    field :form_name, :string
    field :default_unit, :string
    field :default_size_value, :decimal
    field :default_size_unit, :string

    belongs_to :canonical_ingredient, Controlcopypasta.Ingredients.CanonicalIngredient

    timestamps()
  end

  @required_fields [:form_name, :canonical_ingredient_id]
  @optional_fields [:default_unit, :default_size_value, :default_size_unit]

  @valid_forms ~w(fresh canned frozen dried smoked cured pickled fermented powdered ground whole extract paste concentrate jarred boxed bagged)

  @doc """
  Creates a changeset for an ingredient form.
  """
  def changeset(form, attrs) do
    form
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:form_name, min: 1, max: 100)
    |> validate_inclusion(:form_name, @valid_forms)
    |> validate_number(:default_size_value, greater_than: 0)
    |> normalize_form_name()
    |> foreign_key_constraint(:canonical_ingredient_id)
    |> unique_constraint([:canonical_ingredient_id, :form_name])
  end

  defp normalize_form_name(changeset) do
    case get_change(changeset, :form_name) do
      nil -> changeset
      name -> put_change(changeset, :form_name, String.downcase(String.trim(name)))
    end
  end

  @doc """
  Returns valid form name values.
  """
  def valid_forms, do: @valid_forms
end
