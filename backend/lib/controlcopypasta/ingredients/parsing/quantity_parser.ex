defmodule Controlcopypasta.Ingredients.Parsing.QuantityParser do
  @moduledoc """
  Parses quantity strings from ingredient text.

  Handles:
  - Simple numbers: "2", "0.5"
  - Fractions: "1/2", "3/4"
  - Mixed numbers: "1 1/2" (compound quantities)
  - Ranges: "1-2", "2-3"
  - Written numbers: "one", "two"
  """

  alias Controlcopypasta.Ingredients.Tokenizer

  @doc """
  Parses a list of quantity tokens into a value and range.

  Returns `{value, min, max}` where:
  - `value` is the average/best estimate
  - `min` is the lower bound (same as value if no range)
  - `max` is the upper bound (same as value if no range)

  ## Examples

      iex> QuantityParser.parse(["2"])
      {2.0, 2.0, 2.0}

      iex> QuantityParser.parse(["1", "1/2"])
      {1.5, 1.5, 1.5}

      iex> QuantityParser.parse(["1-2"])
      {1.5, 1.0, 2.0}

      iex> QuantityParser.parse([])
      {nil, nil, nil}
  """
  def parse([]), do: {nil, nil, nil}

  def parse(qty_list) when is_list(qty_list) do
    # Find if any quantity token contains a range (e.g., "1-2")
    range_token =
      Enum.find(qty_list, fn qty_str ->
        String.contains?(qty_str, "-") and not String.starts_with?(qty_str, "-")
      end)

    case range_token do
      nil ->
        total = sum_mixed_number(qty_list)
        {total, total, total}

      range_str ->
        # Has range - parse the range, then add any additional fractions to upper bound
        # This handles "1-1 1/2" = range from 1 to 1.5
        case String.split(range_str, "-", parts: 2) do
          [low, high] ->
            low_val = parse_single(low)
            high_val = parse_single(high)

            # Get any additional quantities (fractions) after the range token
            # For "1-1 1/2", qty_list is ["1-1", "1/2"], so we add "1/2" to the upper bound
            idx = Enum.find_index(qty_list, &(&1 == range_str))

            # Only a proper fraction, for the same reason as `sum_mixed_number/1`:
            # in "1-1 1/2" the trailing "1/2" finishes the upper bound, but
            # anything else after a range is not part of it.
            additional =
              qty_list
              |> Enum.drop(idx + 1)
              |> Enum.map(fn str -> {str, parse_single(str)} end)
              |> Enum.take_while(fn {str, value} ->
                not is_nil(value) and proper_fraction?(str, value)
              end)
              |> Enum.map(fn {_str, value} -> value end)

            high_val = if additional != [], do: high_val + Enum.sum(additional), else: high_val
            avg = if low_val && high_val, do: (low_val + high_val) / 2, else: low_val || high_val
            {avg, low_val, high_val}

          _ ->
            val = parse_single(range_str)
            {val, val, val}
        end
    end
  end

  # A whole number followed by a proper fraction is one mixed number, so the
  # parts are added: "1 1/2" is 1.5.
  #
  # Anything else that follows is NOT part of the quantity and is dropped,
  # because adding it invents an amount the line never stated:
  #
  #     2 1 1/4"-thick strip steaks   tokens ["2", "1"] -> 2 steaks, not 3
  #     4 or 5 small red potatoes     tokens ["4", "5"] -> 4-5, not 9
  #
  # The first of those is a dimension the tokenizer could not keep together;
  # the second is a range (`normalize_or_range/1` in TokenParser now rewrites
  # it to "4-5" before tokenizing, so it arrives here as a range token). Both
  # used to be summed, and a count that is 2-3x too high reads straight through
  # to the nutrition totals.
  defp sum_mixed_number(qty_list) do
    values = Enum.map(qty_list, fn str -> {str, parse_single(str)} end)

    case Enum.reject(values, fn {_str, value} -> is_nil(value) end) do
      [] ->
        nil

      [{_str, first} | rest] ->
        total =
          rest
          |> Enum.take_while(fn {str, value} -> proper_fraction?(str, value) end)
          |> Enum.reduce(first, fn {_str, value}, acc -> acc + value end)

        if total == 0, do: nil, else: total
    end
  end

  # Written as a fraction and worth less than one: the only shape that can be
  # the tail of a mixed number. A bare "5" is not, however small.
  defp proper_fraction?(str, value) do
    String.contains?(str, "/") and value > 0 and value < 1
  end

  @doc """
  Parses a single quantity string.

  Handles:
  - Decimals: "2", "0.5", "2.25"
  - Fractions: "1/2", "3/4"
  - Written numbers: "one", "two"

  Returns the numeric value or nil if parsing fails.

  ## Examples

      iex> QuantityParser.parse_single("2")
      2.0

      iex> QuantityParser.parse_single("1/2")
      0.5

      iex> QuantityParser.parse_single("one")
      1.0

      iex> QuantityParser.parse_single("invalid")
      nil
  """
  def parse_single(str) when is_binary(str) do
    str = String.trim(str)

    cond do
      # Written number: "one", "two", etc.
      written_val = Tokenizer.written_number_value(str) ->
        written_val * 1.0

      # Fraction: "1/2"
      String.contains?(str, "/") ->
        case String.split(str, "/") do
          [num, den] ->
            with {n, _} <- Float.parse(num),
                 {d, _} <- Float.parse(den),
                 true <- d != 0 do
              n / d
            else
              _ -> nil
            end

          _ ->
            nil
        end

      # Decimal or integer
      true ->
        case Float.parse(str) do
          {val, _} -> val
          :error -> nil
        end
    end
  end

  def parse_single(nil), do: nil
end
