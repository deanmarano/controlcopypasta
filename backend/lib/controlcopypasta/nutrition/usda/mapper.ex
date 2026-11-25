defmodule Controlcopypasta.Nutrition.Usda.Mapper do
  @moduledoc """
  Turns a FoodData Central food record into the shapes this project stores.

  Two things here are easy to get wrong and are handled explicitly:

  * **Energy is reported twice.** A record carries nutrient 1008 (kcal) and
    1062 (kJ). Reading whichever came first would overstate calories by 4.184x
    on any record that lists kJ first -- "Thyme, fresh" does. Only 1008 is
    read, and a record with no kcal value yields no calories rather than a
    converted guess.

  * **Nutrients are matched by id, not by name.** Names vary across datasets
    ("Total lipid (fat)", "Fatty acids, total saturated") and are localised in
    places; the numeric ids are stable.

  SR Legacy and Foundation report per 100 g, which is what
  `serving_size_value`/`serving_size_unit` record.
  """

  # FDC nutrient id -> our column. Only ids whose unit matches the column's
  # expected unit are listed, so no unit conversion is implied anywhere.
  @nutrient_columns %{
    1008 => :calories,
    1003 => :protein_g,
    1004 => :fat_total_g,
    1258 => :fat_saturated_g,
    1257 => :fat_trans_g,
    1293 => :fat_polyunsaturated_g,
    1292 => :fat_monounsaturated_g,
    1005 => :carbohydrates_g,
    1079 => :fiber_g,
    2000 => :sugar_g,
    1093 => :sodium_mg,
    1092 => :potassium_mg,
    1087 => :calcium_mg,
    1089 => :iron_mg,
    1090 => :magnesium_mg,
    1091 => :phosphorus_mg,
    1095 => :zinc_mg,
    1106 => :vitamin_a_mcg,
    1162 => :vitamin_c_mg,
    1114 => :vitamin_d_mcg,
    1109 => :vitamin_e_mg,
    1185 => :vitamin_k_mcg,
    1175 => :vitamin_b6_mg,
    1178 => :vitamin_b12_mcg,
    1177 => :folate_mcg,
    1165 => :thiamin_mg,
    1166 => :riboflavin_mg,
    1167 => :niacin_mg,
    1253 => :cholesterol_mg,
    1051 => :water_g
  }

  # Units each column is stored in. A record reporting a different unit for one
  # of these is skipped rather than silently rescaled.
  @expected_units %{
    calories: "kcal",
    protein_g: "g",
    fat_total_g: "g",
    fat_saturated_g: "g",
    fat_trans_g: "g",
    fat_polyunsaturated_g: "g",
    fat_monounsaturated_g: "g",
    carbohydrates_g: "g",
    fiber_g: "g",
    sugar_g: "g",
    water_g: "g",
    sodium_mg: "mg",
    potassium_mg: "mg",
    calcium_mg: "mg",
    iron_mg: "mg",
    magnesium_mg: "mg",
    phosphorus_mg: "mg",
    zinc_mg: "mg",
    vitamin_c_mg: "mg",
    vitamin_e_mg: "mg",
    vitamin_b6_mg: "mg",
    thiamin_mg: "mg",
    riboflavin_mg: "mg",
    niacin_mg: "mg",
    cholesterol_mg: "mg",
    vitamin_a_mcg: "µg",
    vitamin_d_mcg: "µg",
    vitamin_k_mcg: "µg",
    vitamin_b12_mcg: "µg",
    folate_mcg: "µg"
  }

  @doc """
  Nutrition attributes for one food record, per 100 g.

  Returns `{:error, :no_calories}` when the record has no kcal value: a
  nutrition row with no calories is worse than none, because the calculator
  would report it as covered.
  """
  @spec nutrition_attrs(map()) :: {:ok, map()} | {:error, atom()}
  def nutrition_attrs(%{"fdcId" => fdc_id} = food) do
    nutrients =
      food
      |> Map.get("foodNutrients", [])
      |> Enum.reduce(%{}, fn entry, acc ->
        with {:ok, column} <- column_for(entry),
             {:ok, value} <- value_for(column, entry) do
          Map.put_new(acc, column, value)
        else
          _ -> acc
        end
      end)

    if is_nil(nutrients[:calories]) do
      {:error, :no_calories}
    else
      {:ok,
       Map.merge(nutrients, %{
         source: :usda,
         source_id: to_string(fdc_id),
         source_name: "USDA FoodData Central - #{Map.get(food, "dataType")}",
         source_url: "https://fdc.nal.usda.gov/fdc-app.html#/food-details/#{fdc_id}/nutrients",
         serving_size_value: 100,
         serving_size_unit: "g",
         serving_description: Map.get(food, "description")
       })}
    end
  end

  def nutrition_attrs(_), do: {:error, :not_a_food_record}

  @doc """
  Portion weights for one food record, as `{amount, unit, grams_per_unit}`.

  FDC gives a gram weight for a stated amount ("0.5 tsp weighs 0.4 g"), so the
  per-unit figure is `gramWeight / amount`. A portion with no usable amount or
  modifier is dropped rather than assumed to be one of something.
  """
  @spec portions(map()) :: [%{unit: String.t(), grams_per_unit: float()}]
  def portions(food) do
    food
    |> Map.get("foodPortions", [])
    |> Enum.flat_map(fn portion ->
      amount = Map.get(portion, "amount")
      grams = Map.get(portion, "gramWeight")
      unit = portion_unit(portion)

      if is_number(amount) and amount > 0 and is_number(grams) and grams > 0 and unit do
        [%{unit: unit, grams_per_unit: grams / amount}]
      else
        []
      end
    end)
    |> Enum.uniq_by(& &1.unit)
  end

  # `measureUnit` is "undetermined" on most SR Legacy rows, with the real unit
  # in `modifier` ("tsp", "sprig"). Prefer the structured field when it says
  # something, fall back to the modifier.
  defp portion_unit(portion) do
    structured =
      case get_in(portion, ["measureUnit", "name"]) do
        name when is_binary(name) and name not in ["", "undetermined"] -> name
        _ -> nil
      end

    modifier =
      case Map.get(portion, "modifier") do
        m when is_binary(m) and m != "" -> m |> String.downcase() |> String.trim()
        _ -> nil
      end

    structured || modifier
  end

  defp column_for(%{"nutrient" => %{"id" => id}}) do
    case Map.fetch(@nutrient_columns, id) do
      {:ok, column} -> {:ok, column}
      :error -> :skip
    end
  end

  defp column_for(_), do: :skip

  defp value_for(column, %{"amount" => amount} = entry) when is_number(amount) do
    reported = get_in(entry, ["nutrient", "unitName"])

    if normalize_unit(reported) == Map.get(@expected_units, column) do
      {:ok, amount}
    else
      :skip
    end
  end

  defp value_for(_column, _entry), do: :skip

  # FDC spells micrograms "UG" and sometimes "µg"; units arrive upper-cased on
  # some endpoints and lower-cased on others.
  defp normalize_unit(nil), do: nil

  defp normalize_unit(unit) do
    case String.downcase(unit) do
      "ug" -> "µg"
      "mcg" -> "µg"
      "µg" -> "µg"
      other -> other
    end
  end
end
