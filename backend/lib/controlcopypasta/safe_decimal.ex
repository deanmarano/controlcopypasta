defmodule Controlcopypasta.SafeDecimal do
  @moduledoc """
  Safe wrapper for Decimal operations that handles edge cases.

  `Decimal.from_float/1` only accepts floats and raises on integers.
  This module provides `from_number/1` which handles both.
  """

  @doc """
  Converts any number to a Decimal, handling both integers and floats.

  Returns nil for nil input.

  ## Examples

      iex> SafeDecimal.from_number(1.5)
      #Decimal<1.5>

      iex> SafeDecimal.from_number(0)
      #Decimal<0>

      iex> SafeDecimal.from_number(nil)
      nil
  """
  def from_number(nil), do: nil
  def from_number(val) when is_integer(val), do: Decimal.new(val)
  def from_number(val) when is_float(val), do: Decimal.from_float(val)
  def from_number(%Decimal{} = val), do: val

  @doc """
  Multiplies a number by a factor and converts to Decimal.

  Useful for unit conversions (e.g., grams to milligrams).

  ## Examples

      iex> SafeDecimal.from_number_with_factor(0.5, 1000)
      #Decimal<500.0>

      iex> SafeDecimal.from_number_with_factor(0, 1000)
      #Decimal<0>
  """
  def from_number_with_factor(nil, _factor), do: nil

  def from_number_with_factor(val, factor) when is_number(val) and is_number(factor) do
    # Ensure float result
    from_number(val * factor / 1.0)
  end
end
