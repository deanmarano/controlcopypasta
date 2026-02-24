defmodule Controlcopypasta.Ingredients.IngredientNutrition do
  @moduledoc """
  Schema for ingredient nutrition data from multiple sources.

  ## Data Source Trust Hierarchy

  Sources are ranked by reliability (highest to lowest):

  1. **usda** - USDA FoodData Central (government, scientific, most trusted)
  2. **manual** - Manually entered/verified by us
  3. **fatsecret** - FatSecret API, good for branded products
  4. **open_food_facts** - Community database, good for international products
  5. **nutritionix** - Commercial API, generally reliable
  6. **estimated** - Calculated or estimated values

  When displaying nutrition, prefer the `is_primary` record or fall back to
  the highest-trust source available.

  ## Confidence Tracking

  Each nutrition record has a `confidence` score (0.0-1.0) that indicates
  how reliable the data is. This helps identify ingredients that need
  better nutrition data.

  ### Confidence Factors

  The `confidence_factors` map breaks down what contributed to the score:

  - `source_reliability` - Base trust of the source (USDA=0.95, estimated=0.30)
  - `data_completeness` - Ratio of nutrition fields populated
  - `staleness_penalty` - Decay if data hasn't been verified recently
  - `verified_bonus` - Boost if manually verified

  ### Finding Low-Confidence Ingredients

      # Ingredients needing improvement (low confidence, high usage)
      from n in IngredientNutrition,
        join: i in CanonicalIngredient, on: n.canonical_ingredient_id == i.id,
        where: n.is_primary == true and n.confidence < 0.6,
        order_by: [asc: n.confidence, desc: i.usage_count]

  ## Standard Reference

  All nutrition values are stored per `serving_size_value` `serving_size_unit`.
  USDA data typically uses 100g as the reference. To calculate recipe nutrition,
  convert ingredient amounts to the reference unit and multiply.

  ## Examples

      %IngredientNutrition{
        source: :usda,
        source_id: "171287",
        serving_size_value: Decimal.new("100"),
        serving_size_unit: "g",
        calories: Decimal.new("52"),
        protein_g: Decimal.new("0.26"),
        carbohydrates_g: Decimal.new("13.81"),
        fiber_g: Decimal.new("2.4"),
        sugar_g: Decimal.new("10.39"),
        is_primary: true,
        confidence: Decimal.new("0.87"),
        confidence_factors: %{
          "source_reliability" => 0.95,
          "data_completeness" => 0.86,
          "staleness_penalty" => 0.0,
          "verified_bonus" => 0.0
        }
      }
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Controlcopypasta.Ingredients.CanonicalIngredient

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Source trust order (highest to lowest)
  @source_trust_order [:usda, :manual, :fatsecret, :open_food_facts, :nutritionix, :estimated]

  schema "ingredient_nutrition" do
    belongs_to :canonical_ingredient, CanonicalIngredient

    # Source tracking
    field :source, Ecto.Enum, values: @source_trust_order
    field :source_id, :string
    field :source_name, :string
    field :source_url, :string

    # Reference amount
    field :serving_size_value, :decimal
    field :serving_size_unit, :string
    field :serving_description, :string

    # Macronutrients
    field :calories, :decimal
    field :protein_g, :decimal
    field :fat_total_g, :decimal
    field :fat_saturated_g, :decimal
    field :fat_trans_g, :decimal
    field :fat_polyunsaturated_g, :decimal
    field :fat_monounsaturated_g, :decimal
    field :carbohydrates_g, :decimal
    field :fiber_g, :decimal
    field :sugar_g, :decimal
    field :sugar_added_g, :decimal

    # Minerals
    field :sodium_mg, :decimal
    field :potassium_mg, :decimal
    field :calcium_mg, :decimal
    field :iron_mg, :decimal
    field :magnesium_mg, :decimal
    field :phosphorus_mg, :decimal
    field :zinc_mg, :decimal

    # Vitamins
    field :vitamin_a_mcg, :decimal
    field :vitamin_c_mg, :decimal
    field :vitamin_d_mcg, :decimal
    field :vitamin_e_mg, :decimal
    field :vitamin_k_mcg, :decimal
    field :vitamin_b6_mg, :decimal
    field :vitamin_b12_mcg, :decimal
    field :folate_mcg, :decimal
    field :thiamin_mg, :decimal
    field :riboflavin_mg, :decimal
    field :niacin_mg, :decimal

    # Other
    field :cholesterol_mg, :decimal
    field :water_g, :decimal

    # Metadata
    field :is_primary, :boolean, default: false
    field :verified_at, :utc_datetime
    field :notes, :string

    # Confidence tracking
    field :confidence, :decimal
    field :confidence_factors, :map
    field :retrieved_at, :utc_datetime
    field :last_checked_at, :utc_datetime

    timestamps()
  end

  @required_fields [:canonical_ingredient_id, :source, :serving_size_value, :serving_size_unit]
  @optional_fields [
    :source_id,
    :source_name,
    :source_url,
    :serving_description,
    :calories,
    :protein_g,
    :fat_total_g,
    :fat_saturated_g,
    :fat_trans_g,
    :fat_polyunsaturated_g,
    :fat_monounsaturated_g,
    :carbohydrates_g,
    :fiber_g,
    :sugar_g,
    :sugar_added_g,
    :sodium_mg,
    :potassium_mg,
    :calcium_mg,
    :iron_mg,
    :magnesium_mg,
    :phosphorus_mg,
    :zinc_mg,
    :vitamin_a_mcg,
    :vitamin_c_mg,
    :vitamin_d_mcg,
    :vitamin_e_mg,
    :vitamin_k_mcg,
    :vitamin_b6_mg,
    :vitamin_b12_mcg,
    :folate_mcg,
    :thiamin_mg,
    :riboflavin_mg,
    :niacin_mg,
    :cholesterol_mg,
    :water_g,
    :is_primary,
    :verified_at,
    :notes,
    :confidence,
    :confidence_factors,
    :retrieved_at,
    :last_checked_at
  ]

  @valid_units ~w(g mg ml oz lb cup tbsp tsp serving piece)

  @doc """
  Creates a changeset for ingredient nutrition.
  """
  def changeset(nutrition, attrs) do
    nutrition
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:serving_size_unit, @valid_units)
    |> validate_number(:serving_size_value, greater_than: 0)
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_non_negative_nutrients()
    |> unique_constraint([:canonical_ingredient_id, :source, :source_id])
  end

  defp validate_non_negative_nutrients(changeset) do
    nutrient_fields = [
      :calories,
      :protein_g,
      :fat_total_g,
      :fat_saturated_g,
      :fat_trans_g,
      :carbohydrates_g,
      :fiber_g,
      :sugar_g,
      :sodium_mg,
      :potassium_mg,
      :calcium_mg,
      :iron_mg,
      :cholesterol_mg
    ]

    Enum.reduce(nutrient_fields, changeset, fn field, cs ->
      validate_number(cs, field, greater_than_or_equal_to: 0)
    end)
  end

  @doc """
  Returns the source trust order, from most to least trusted.
  """
  def source_trust_order, do: @source_trust_order

  @doc """
  Returns the trust level for a source (lower = more trusted).
  """
  def trust_level(source) when is_atom(source) do
    Enum.find_index(@source_trust_order, &(&1 == source)) || 999
  end

  @doc """
  Compares two sources by trust level. Returns true if source_a is more trusted.
  """
  def more_trusted?(source_a, source_b) do
    trust_level(source_a) < trust_level(source_b)
  end

  @doc """
  Macro nutrient fields for common queries.
  """
  def macro_fields do
    [:calories, :protein_g, :fat_total_g, :carbohydrates_g, :fiber_g, :sugar_g, :sodium_mg]
  end

  @doc """
  All nutrient fields for complete nutrition display.
  """
  def all_nutrient_fields do
    [
      :calories,
      :protein_g,
      :fat_total_g,
      :fat_saturated_g,
      :fat_trans_g,
      :fat_polyunsaturated_g,
      :fat_monounsaturated_g,
      :carbohydrates_g,
      :fiber_g,
      :sugar_g,
      :sugar_added_g,
      :sodium_mg,
      :potassium_mg,
      :calcium_mg,
      :iron_mg,
      :magnesium_mg,
      :phosphorus_mg,
      :zinc_mg,
      :vitamin_a_mcg,
      :vitamin_c_mg,
      :vitamin_d_mcg,
      :vitamin_e_mg,
      :vitamin_k_mcg,
      :vitamin_b6_mg,
      :vitamin_b12_mcg,
      :folate_mcg,
      :thiamin_mg,
      :riboflavin_mg,
      :niacin_mg,
      :cholesterol_mg,
      :water_g
    ]
  end

  # Base confidence scores by source type
  @source_base_confidence %{
    usda: Decimal.new("0.95"),
    manual: Decimal.new("0.85"),
    fatsecret: Decimal.new("0.80"),
    open_food_facts: Decimal.new("0.70"),
    nutritionix: Decimal.new("0.75"),
    estimated: Decimal.new("0.30")
  }

  @doc """
  Returns the base confidence score for a given source type.
  """
  def base_confidence_for_source(source) when is_atom(source) do
    Map.get(@source_base_confidence, source, Decimal.new("0.50"))
  end

  @doc """
  Calculates the data completeness ratio (0.0 to 1.0) based on how many
  macro nutrient fields are populated.
  """
  def data_completeness(%__MODULE__{} = nutrition) do
    fields = macro_fields()
    populated = Enum.count(fields, fn field -> not is_nil(Map.get(nutrition, field)) end)
    Decimal.div(Decimal.new(populated), Decimal.new(length(fields)))
  end

  @doc """
  Calculates and returns a confidence score with breakdown factors.

  Returns `{confidence_score, factors_map}` where:
  - `confidence_score` is a Decimal between 0.0 and 1.0
  - `factors_map` explains how the score was calculated

  ## Factors considered:
  - `source_reliability` - Base trust of the data source
  - `data_completeness` - Percentage of nutrition fields populated
  - `staleness_penalty` - Decay if data hasn't been verified recently
  - `verified_bonus` - Boost if manually verified
  """
  def calculate_confidence(%__MODULE__{} = nutrition) do
    source_reliability = base_confidence_for_source(nutrition.source)
    completeness = data_completeness(nutrition)

    # Staleness penalty: reduce confidence if last_checked_at is old
    staleness_penalty = calculate_staleness_penalty(nutrition.last_checked_at)

    # Verified bonus: boost if verified_at is set
    verified_bonus = if nutrition.verified_at, do: Decimal.new("0.05"), else: Decimal.new("0")

    # Weighted calculation
    # source_reliability: 50%, completeness: 30%, staleness: 10%, verified: 10%
    weighted_score =
      Decimal.mult(source_reliability, Decimal.new("0.50"))
      |> Decimal.add(Decimal.mult(completeness, Decimal.new("0.30")))
      |> Decimal.sub(Decimal.mult(staleness_penalty, Decimal.new("0.10")))
      |> Decimal.add(Decimal.mult(verified_bonus, Decimal.new("0.10")))

    # Clamp to 0.0-1.0
    confidence =
      weighted_score
      |> Decimal.max(Decimal.new("0"))
      |> Decimal.min(Decimal.new("1"))
      |> Decimal.round(2)

    factors = %{
      "source_reliability" => Decimal.to_float(source_reliability),
      "data_completeness" => Decimal.to_float(Decimal.round(completeness, 2)),
      "staleness_penalty" => Decimal.to_float(staleness_penalty),
      "verified_bonus" => Decimal.to_float(verified_bonus)
    }

    {confidence, factors}
  end

  defp calculate_staleness_penalty(nil), do: Decimal.new("0.20")

  defp calculate_staleness_penalty(last_checked_at) do
    days_since = DateTime.diff(DateTime.utc_now(), last_checked_at, :day)

    cond do
      days_since < 30 -> Decimal.new("0")
      days_since < 90 -> Decimal.new("0.05")
      days_since < 180 -> Decimal.new("0.10")
      days_since < 365 -> Decimal.new("0.15")
      true -> Decimal.new("0.20")
    end
  end

  @doc """
  Updates a nutrition record with calculated confidence.
  Returns an updated changeset with confidence and confidence_factors set.
  """
  def with_calculated_confidence(%Ecto.Changeset{} = changeset) do
    nutrition = Ecto.Changeset.apply_changes(changeset)
    {confidence, factors} = calculate_confidence(nutrition)

    changeset
    |> Ecto.Changeset.put_change(:confidence, confidence)
    |> Ecto.Changeset.put_change(:confidence_factors, factors)
  end
end
