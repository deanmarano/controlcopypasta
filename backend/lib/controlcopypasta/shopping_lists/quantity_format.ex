defmodule Controlcopypasta.ShoppingLists.QuantityFormat do
  @moduledoc """
  Formats shopping list quantities the way a person would write them:
  "½" rather than "0.50", "1 ¾" rather than "1.75".

  Kitchen units snap to the nearest common fraction (rounding up on a tie, since
  buying slightly too much beats too little). Metric units keep decimals.
  """

  @metric_units ~w(g gram grams kg kilogram kilograms ml milliliter milliliters l liter liters)

  # {value, glyph}; 0 and 1 are the "no fraction" ends of the scale.
  @steps [
    {0.0, nil},
    {0.125, "⅛"},
    {0.25, "¼"},
    {1 / 3, "⅓"},
    {0.375, "⅜"},
    {0.5, "½"},
    {0.625, "⅝"},
    {2 / 3, "⅔"},
    {0.75, "¾"},
    {0.875, "⅞"},
    {1.0, nil}
  ]

  @doc "Formats a quantity for display next to `unit` (which may be nil)."
  def format(quantity, unit \\ nil)

  def format(%Decimal{} = quantity, unit) do
    cond do
      metric?(unit) -> decimal_string(quantity)
      Decimal.compare(quantity, Decimal.new(0)) != :gt -> decimal_string(quantity)
      true -> fraction_string(Decimal.to_float(quantity))
    end
  end

  def format(quantity, _unit), do: to_string(quantity)

  defp metric?(nil), do: false
  defp metric?(unit), do: String.downcase(String.trim(unit)) in @metric_units

  defp fraction_string(value) do
    whole = trunc(value)
    frac = value - whole

    # Reversed so that an exact tie between two steps picks the larger one.
    {step, glyph} =
      @steps
      |> Enum.reverse()
      |> Enum.min_by(fn {step, _glyph} -> abs(step - frac) end)

    cond do
      # Never round a real amount down to nothing.
      step == 0.0 and whole == 0 -> "⅛"
      step == 0.0 -> Integer.to_string(whole)
      step == 1.0 -> Integer.to_string(whole + 1)
      whole == 0 -> glyph
      true -> "#{whole} #{glyph}"
    end
  end

  defp decimal_string(quantity) do
    quantity
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
    |> trim_zeros()
  end

  defp trim_zeros(string) do
    if String.contains?(string, ".") do
      string |> String.trim_trailing("0") |> String.trim_trailing(".")
    else
      string
    end
  end
end
