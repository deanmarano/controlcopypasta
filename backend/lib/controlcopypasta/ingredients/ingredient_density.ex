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
  @valid_volume_units ~w(cup tbsp tsp oz pint quart gallon ml liter each whole
                        can block slice leaf fillet pinch piece bunch stalk sprig) ++
                        ["fl oz"]
  @valid_sources ~w(usda fatsecret openfoodfacts manual calculated standard\ estimate)
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
    # USDA portion ID or FatSecret serving_id
    field :source_id, :string
    # Link to source data
    field :source_url, :string
    # 0.0-1.0 data quality score
    field :confidence, :decimal
    # USDA: number of measurements
    field :data_points, :integer
    # When fetched from API
    field :retrieved_at, :utc_datetime
    field :last_checked_at, :utc_datetime

    timestamps()
  end

  @required_fields [:canonical_ingredient_id, :volume_unit, :grams_per_unit, :source]
  @optional_fields [
    :preparation,
    :notes,
    :source_id,
    :source_url,
    :confidence,
    :data_points,
    :retrieved_at,
    :last_checked_at
  ]

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
    |> validate_plausible_density()
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:data_points, greater_than_or_equal_to: 0)
    |> unique_constraint([:canonical_ingredient_id, :volume_unit, :preparation, :source],
      name: :ingredient_densities_unique_idx
    )
  end

  # Approximate millilitres for the units that measure a volume. Count units
  # ("each", "slice", "can", ...) are left out: they have no volume, so no
  # gram weight is implausible for them.
  @unit_ml %{
    "cup" => 236.6,
    "tbsp" => 14.8,
    "tsp" => 4.9,
    "oz" => 29.6,
    "fl oz" => 29.6,
    "pint" => 473.0,
    "quart" => 946.0,
    "gallon" => 3785.0,
    "ml" => 1.0,
    "liter" => 1000.0
  }

  # Nothing edible is less dense than about 0.01 g/ml (puffed grains sit near
  # 0.04, fresh basil leaves near 0.025) or denser than about 2.0 (salt is 1.2,
  # honey 1.4). A value outside that is not a density.
  @min_g_per_ml 0.01
  @max_g_per_ml 2.0

  # 43 of the 1,539 density rows in production fail this check, and they fail it
  # the same way: a serving volume was written into the grams column. Pepsi is
  # recorded as 710 g per fl oz (a 710 ml bottle), porter as 354 (a 354 ml can),
  # coffee as 237 (a 237 ml cup), wine as 147 (a 5 oz pour). For 27 of them it
  # is the only row for that unit, so the wrong number is the one that gets
  # used -- "1 fl oz of pepsi" is costed as 710 g.
  #
  # This stops new rows of that shape being written. The existing ones are data
  # to correct separately.
  defp validate_plausible_density(changeset) do
    unit = get_field(changeset, :volume_unit)
    grams = get_field(changeset, :grams_per_unit)

    with ml when is_float(ml) <- Map.get(@unit_ml, unit),
         true <- not is_nil(grams) do
      ratio = Decimal.to_float(Decimal.new(grams)) / ml

      cond do
        ratio < @min_g_per_ml ->
          add_error(
            changeset,
            :grams_per_unit,
            "is implausibly light for one #{unit} (#{Float.round(ratio, 4)} g/ml)"
          )

        ratio > @max_g_per_ml ->
          add_error(
            changeset,
            :grams_per_unit,
            "is implausibly heavy for one #{unit} (#{Float.round(ratio, 2)} g/ml); " <>
              "a serving volume may have been recorded as grams"
          )

        true ->
          changeset
      end
    else
      _ -> changeset
    end
  end

  @doc """
  Returns the approximate millilitres for each volume unit, for the units that
  measure a volume at all.
  """
  def unit_ml, do: @unit_ml

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
