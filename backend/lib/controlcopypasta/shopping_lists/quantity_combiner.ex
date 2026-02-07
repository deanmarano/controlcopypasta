defmodule Controlcopypasta.ShoppingLists.QuantityCombiner do
  @moduledoc """
  Handles unit conversion and quantity combining for shopping list items.
  """

  alias Controlcopypasta.SafeDecimal

  # Volume conversions to milliliters
  @volume_to_ml %{
    "cup" => 236.588,
    "cups" => 236.588,
    "c" => 236.588,
    "tbsp" => 14.787,
    "tablespoon" => 14.787,
    "tablespoons" => 14.787,
    "tsp" => 4.929,
    "teaspoon" => 4.929,
    "teaspoons" => 4.929,
    "fl oz" => 29.574,
    "fluid oz" => 29.574,
    "fluid ounce" => 29.574,
    "fluid ounces" => 29.574,
    "ml" => 1.0,
    "milliliter" => 1.0,
    "milliliters" => 1.0,
    "l" => 1000.0,
    "liter" => 1000.0,
    "liters" => 1000.0,
    "quart" => 946.353,
    "quarts" => 946.353,
    "qt" => 946.353,
    "pint" => 473.176,
    "pints" => 473.176,
    "pt" => 473.176,
    "gallon" => 3785.41,
    "gallons" => 3785.41,
    "gal" => 3785.41
  }

  # Weight conversions to grams
  @weight_to_g %{
    "oz" => 28.3495,
    "ounce" => 28.3495,
    "ounces" => 28.3495,
    "lb" => 453.592,
    "lbs" => 453.592,
    "pound" => 453.592,
    "pounds" => 453.592,
    "g" => 1.0,
    "gram" => 1.0,
    "grams" => 1.0,
    "kg" => 1000.0,
    "kilogram" => 1000.0,
    "kilograms" => 1000.0
  }

  # Preferred display units (largest sensible unit for display)
  @volume_display_order [
    {"gallon", 3785.41},
    {"quart", 946.353},
    {"cup", 236.588},
    {"tbsp", 14.787},
    {"tsp", 4.929}
  ]

  @weight_display_order [
    {"lb", 453.592},
    {"oz", 28.3495}
  ]

  @doc """
  Attempts to combine two quantities with their units.
  Returns {:ok, {combined_quantity, combined_unit}} or {:incompatible, reason}.
  """
  def combine(qty1, unit1, qty2, unit2) do
    unit1_norm = normalize_unit(unit1)
    unit2_norm = normalize_unit(unit2)

    cond do
      # Same unit - just add
      unit1_norm == unit2_norm ->
        {:ok, {Decimal.add(qty1, qty2), unit1}}

      # Both volume units
      is_volume_unit?(unit1_norm) and is_volume_unit?(unit2_norm) ->
        combine_volumes(qty1, unit1_norm, qty2, unit2_norm)

      # Both weight units
      is_weight_unit?(unit1_norm) and is_weight_unit?(unit2_norm) ->
        combine_weights(qty1, unit1_norm, qty2, unit2_norm)

      # Incompatible units
      true ->
        {:incompatible, "Cannot combine #{unit1} with #{unit2}"}
    end
  end

  @doc """
  Checks if two items can be combined based on canonical_id, canonical_name, or raw_name.
  """
  def can_combine?(item1, item2) do
    cond do
      # Same canonical ingredient ID
      item1.canonical_ingredient_id && item1.canonical_ingredient_id == item2.canonical_ingredient_id ->
        true

      # Same canonical name
      item1.canonical_name && normalize_name(item1.canonical_name) == normalize_name(item2.canonical_name) ->
        true

      # Similar raw names
      item1.raw_name && item2.raw_name && fuzzy_match?(item1.raw_name, item2.raw_name) ->
        true

      true ->
        false
    end
  end

  @doc """
  Attempts to merge two shopping list items.
  Returns {:ok, merged_attrs} or {:incompatible, reason}.
  """
  def merge_items(existing_item, new_item_attrs) do
    cond do
      # If either has no quantity, we can't combine mathematically
      is_nil(existing_item.quantity) or is_nil(new_item_attrs[:quantity]) ->
        {:incompatible, "Cannot combine items without quantities"}

      # If either has no unit, we can't combine
      is_nil(existing_item.unit) or is_nil(new_item_attrs[:unit]) ->
        {:incompatible, "Cannot combine items without units"}

      true ->
        case combine(existing_item.quantity, existing_item.unit, new_item_attrs[:quantity], new_item_attrs[:unit]) do
          {:ok, {new_qty, new_unit}} ->
            source_ids = merge_source_ids(existing_item.source_recipe_ids, new_item_attrs[:source_recipe_ids])
            new_display = format_display_text(new_qty, new_unit, existing_item.canonical_name || existing_item.raw_name)

            {:ok, %{
              quantity: new_qty,
              unit: new_unit,
              display_text: new_display,
              source_recipe_ids: source_ids
            }}

          {:incompatible, reason} ->
            {:incompatible, reason}
        end
    end
  end

  # Private functions

  defp normalize_unit(nil), do: nil
  defp normalize_unit(unit), do: String.downcase(String.trim(unit))

  defp normalize_name(nil), do: nil
  defp normalize_name(name), do: name |> String.downcase() |> String.trim()

  defp is_volume_unit?(nil), do: false
  defp is_volume_unit?(unit), do: Map.has_key?(@volume_to_ml, unit)

  defp is_weight_unit?(nil), do: false
  defp is_weight_unit?(unit), do: Map.has_key?(@weight_to_g, unit)

  defp combine_volumes(qty1, unit1, qty2, unit2) do
    ml1 = Decimal.mult(qty1, SafeDecimal.from_number(@volume_to_ml[unit1]))
    ml2 = Decimal.mult(qty2, SafeDecimal.from_number(@volume_to_ml[unit2]))
    total_ml = Decimal.add(ml1, ml2)

    {display_unit, display_qty} = convert_to_best_volume_unit(total_ml)
    {:ok, {display_qty, display_unit}}
  end

  defp combine_weights(qty1, unit1, qty2, unit2) do
    g1 = Decimal.mult(qty1, SafeDecimal.from_number(@weight_to_g[unit1]))
    g2 = Decimal.mult(qty2, SafeDecimal.from_number(@weight_to_g[unit2]))
    total_g = Decimal.add(g1, g2)

    {display_unit, display_qty} = convert_to_best_weight_unit(total_g)
    {:ok, {display_qty, display_unit}}
  end

  defp convert_to_best_volume_unit(ml) do
    find_best_unit(ml, @volume_display_order)
  end

  defp convert_to_best_weight_unit(g) do
    find_best_unit(g, @weight_display_order)
  end

  defp find_best_unit(value, unit_order) do
    # Find the largest unit where the result is >= 1
    Enum.find_value(unit_order, fn {unit, factor} ->
      converted = Decimal.div(value, SafeDecimal.from_number(factor))
      if Decimal.compare(converted, Decimal.new(1)) in [:gt, :eq] do
        {unit, round_decimal(converted)}
      end
    end) ||
      # Fall back to smallest unit
      case List.last(unit_order) do
        {unit, factor} ->
          {unit, round_decimal(Decimal.div(value, SafeDecimal.from_number(factor)))}
      end
  end

  defp round_decimal(d) do
    # Round to 2 decimal places, but show as integer if whole number
    rounded = Decimal.round(d, 2)
    if Decimal.equal?(rounded, Decimal.round(rounded, 0)) do
      Decimal.round(rounded, 0)
    else
      rounded
    end
  end

  defp fuzzy_match?(name1, name2) do
    n1 = normalize_name(name1)
    n2 = normalize_name(name2)

    # Exact match
    n1 == n2 ||
      # One contains the other
      String.contains?(n1, n2) ||
      String.contains?(n2, n1) ||
      # Remove common suffixes and compare
      strip_plurals(n1) == strip_plurals(n2)
  end

  defp strip_plurals(name) do
    name
    |> String.replace(~r/ies$/, "y")
    |> String.replace(~r/es$/, "")
    |> String.replace(~r/s$/, "")
  end

  defp merge_source_ids(existing_ids, new_ids) do
    existing = existing_ids || []
    new = new_ids || []
    Enum.uniq(existing ++ new)
  end

  defp format_display_text(quantity, unit, name) do
    qty_str = format_quantity(quantity)
    "#{qty_str} #{unit} #{name}"
  end

  defp format_quantity(d) when is_struct(d, Decimal) do
    d
    |> Decimal.to_string(:normal)
    |> String.replace(~r/\.0+$/, "")
  end
  defp format_quantity(n), do: to_string(n)
end
