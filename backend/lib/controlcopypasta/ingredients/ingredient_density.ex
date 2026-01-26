defmodule Controlcopypasta.Ingredients.IngredientDensity do
  @moduledoc """
  Schema for ingredient density data used to convert volume measurements to grams.

  This enables nutrition calculations by converting recipes like "1 cup flour"
  into grams, which can then be used with per-100g nutrition data.

  ## Fields

  - `canonical_ingredient_id` - Reference to the canonical ingredient
  - `volume_unit` - The unit this density applies to ("cup", "tbsp", "tsp", "each", "whole")
  - `grams_per_unit` - Weight in grams for one unit of volume
  - `preparation` - Optional preparation that affects density ("packed", "sifted", etc.)
  - `source` - Where this data came from ("usda", "manual", "calculated")
  - `notes` - Optional notes about the measurement

  ## Examples

      %IngredientDensity{
        volume_unit: "cup",
        grams_per_unit: Decimal.new("125"),
        preparation: nil,
        source: "usda"
      }

      %IngredientDensity{
        volume_unit: "cup",
        grams_per_unit: Decimal.new("220"),
        preparation: "packed",
        source: "usda"
      }
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Controlcopypasta.Ingredients.CanonicalIngredient

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Volume units plus "each"/"whole" for countable items (eggs, lemons, etc.)
  @valid_volume_units ~w(cup tbsp tsp fl oz pint quart gallon ml liter each whole)
  @valid_sources ~w(usda manual calculated)
  @valid_preparations ~w(packed sifted chopped diced minced sliced grated shredded whole)

  schema "ingredient_densities" do
    belongs_to :canonical_ingredient, CanonicalIngredient

    field :volume_unit, :string
    field :grams_per_unit, :decimal
    field :preparation, :string
    field :source, :string
    field :notes, :string

    timestamps()
  end

  @required_fields [:canonical_ingredient_id, :volume_unit, :grams_per_unit, :source]
  @optional_fields [:preparation, :notes]

  @doc """
  Creates a changeset for an ingredient density.
  """
  def changeset(density, attrs) do
    density
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:volume_unit, @valid_volume_units)
    |> validate_inclusion(:source, @valid_sources)
    |> validate_inclusion(:preparation, @valid_preparations ++ [nil])
    |> validate_number(:grams_per_unit, greater_than: 0)
    |> unique_constraint([:canonical_ingredient_id, :volume_unit, :preparation],
      name: :ingredient_densities_unique_combo
    )
  end

  @doc """
  Returns valid volume units.
  """
  def valid_volume_units, do: @valid_volume_units

  @doc """
  Returns valid sources.
  """
  def valid_sources, do: @valid_sources

  @doc """
  Returns valid preparations.
  """
  def valid_preparations, do: @valid_preparations
end
