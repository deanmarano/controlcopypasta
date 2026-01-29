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
  # Note: "oz" is included because recipes often use it for fluid ounces
  @valid_volume_units ["cup", "tbsp", "tsp", "fl oz", "oz", "pint", "quart", "gallon", "ml", "liter", "each", "whole"]
  @valid_sources ~w(usda fatsecret manual calculated standard\ estimate)
  @valid_preparations ~w(packed sifted chopped diced minced sliced grated shredded whole
                         cubed chunks sections flaked canned cooked drained crumbled
                         crushed kernels ground chips fresh\ minced beaten)

  schema "ingredient_densities" do
    belongs_to :canonical_ingredient, CanonicalIngredient

    field :volume_unit, :string
    field :grams_per_unit, :decimal
    field :preparation, :string
    field :source, :string
    field :notes, :string

    # Provenance tracking (matching IngredientNutrition pattern)
    field :source_id, :string          # USDA portion ID or FatSecret serving_id
    field :source_url, :string         # Link to source data
    field :confidence, :decimal        # 0.0-1.0 data quality score
    field :data_points, :integer       # USDA: number of measurements
    field :retrieved_at, :utc_datetime # When fetched from API
    field :last_checked_at, :utc_datetime

    timestamps()
  end

  @required_fields [:canonical_ingredient_id, :volume_unit, :grams_per_unit, :source]
  @optional_fields [:preparation, :notes, :source_id, :source_url, :confidence, :data_points,
                    :retrieved_at, :last_checked_at]

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
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:data_points, greater_than_or_equal_to: 0)
    |> unique_constraint([:canonical_ingredient_id, :volume_unit, :preparation],
      name: :ingredient_densities_unique_idx
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
