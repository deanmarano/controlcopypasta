defmodule Controlcopypasta.Nutrition.Range do
  @moduledoc """
  Represents a nutrition value range with uncertainty tracking.

  Uncertainty can come from:
  1. Quantity ranges in recipe text ("5 to 6 ounces")
  2. Density variations (packed vs loose, count item sizes)
  3. Nutrition source confidence (USDA=95%, estimates=30%)

  ## Structure

  - `min` - Lower bound of the range
  - `best` - Best estimate (usually middle value)
  - `max` - Upper bound of the range
  - `confidence` - Overall confidence score (0.0-1.0)
  """

  defstruct [:min, :best, :max, :confidence]

  @type t :: %__MODULE__{
          min: float() | nil,
          best: float() | nil,
          max: float() | nil,
          confidence: float()
        }

  @doc """
  Creates a range from a single value with optional confidence.

  When there's no uncertainty, min = best = max.

  ## Examples

      iex> Range.from_single(100)
      %Range{min: 100.0, best: 100.0, max: 100.0, confidence: 1.0}

      iex> Range.from_single(100, 0.8)
      %Range{min: 100.0, best: 100.0, max: 100.0, confidence: 0.8}
  """
  @spec from_single(number() | nil, float()) :: t()
  def from_single(value, confidence \\ 1.0)

  def from_single(value, confidence) when is_number(value) do
    float_value = to_float(value)

    %__MODULE__{
      min: float_value,
      best: float_value,
      max: float_value,
      confidence: confidence
    }
  end

  def from_single(nil, confidence) do
    %__MODULE__{min: nil, best: nil, max: nil, confidence: confidence}
  end

  @doc """
  Creates a range from explicit min, best, max values.

  ## Examples

      iex> Range.from_range(90, 100, 110, 0.9)
      %Range{min: 90.0, best: 100.0, max: 110.0, confidence: 0.9}
  """
  @spec from_range(number(), number(), number(), float()) :: t()
  def from_range(min, best, max, confidence \\ 1.0) do
    %__MODULE__{
      min: to_float(min),
      best: to_float(best),
      max: to_float(max),
      confidence: confidence
    }
  end

  @doc """
  Creates a range from a value with percentage variation.

  ## Examples

      iex> Range.from_value_with_variation(100, 0.15)
      %Range{min: 85.0, best: 100.0, max: 115.0, confidence: 1.0}
  """
  @spec from_value_with_variation(number(), float(), float()) :: t()
  def from_value_with_variation(value, variation_pct, confidence \\ 1.0) do
    float_value = to_float(value)

    %__MODULE__{
      min: float_value * (1 - variation_pct),
      best: float_value,
      max: float_value * (1 + variation_pct),
      confidence: confidence
    }
  end

  @doc """
  Adds two ranges together, propagating uncertainty.

  The resulting range has:
  - min = min1 + min2
  - best = best1 + best2
  - max = max1 + max2
  - confidence = weighted average by best values

  ## Examples

      iex> r1 = Range.from_range(90, 100, 110, 0.9)
      iex> r2 = Range.from_range(40, 50, 60, 0.8)
      iex> Range.add(r1, r2)
      %Range{min: 130.0, best: 150.0, max: 170.0, confidence: ...}
  """
  @spec add(t(), t()) :: t()
  def add(%__MODULE__{} = r1, %__MODULE__{} = r2) do
    if is_nil(r1.best) or is_nil(r2.best) do
      # If either is nil, return the non-nil one or a nil range
      cond do
        is_nil(r1.best) and is_nil(r2.best) -> from_single(nil, 0.0)
        is_nil(r1.best) -> r2
        is_nil(r2.best) -> r1
      end
    else
      # Weighted average confidence based on best values
      total_best = r1.best + r2.best

      combined_confidence =
        if total_best > 0 do
          (r1.confidence * r1.best + r2.confidence * r2.best) / total_best
        else
          (r1.confidence + r2.confidence) / 2
        end

      %__MODULE__{
        min: r1.min + r2.min,
        best: r1.best + r2.best,
        max: r1.max + r2.max,
        confidence: combined_confidence
      }
    end
  end

  @doc """
  Multiplies a range by a scalar value.

  ## Examples

      iex> r = Range.from_range(90, 100, 110, 0.9)
      iex> Range.multiply(r, 2)
      %Range{min: 180.0, best: 200.0, max: 220.0, confidence: 0.9}
  """
  @spec multiply(t(), number()) :: t()
  def multiply(%__MODULE__{} = range, scalar) when is_number(scalar) do
    if is_nil(range.best) do
      range
    else
      float_scalar = to_float(scalar)

      %__MODULE__{
        min: range.min * float_scalar,
        best: range.best * float_scalar,
        max: range.max * float_scalar,
        confidence: range.confidence
      }
    end
  end

  @doc """
  Multiplies two ranges together, combining uncertainties.

  Used when multiplying quantity range by density range.
  The combined range captures the full uncertainty space.

  ## Examples

      iex> qty = Range.from_range(5, 5.5, 6, 0.9)      # 5-6 oz
      iex> density = Range.from_range(28, 28.35, 29, 0.95)  # oz to grams
      iex> Range.multiply_ranges(qty, density)
      %Range{min: 140.0, best: 156.0, max: 174.0, ...}
  """
  @spec multiply_ranges(t(), t()) :: t()
  def multiply_ranges(%__MODULE__{} = r1, %__MODULE__{} = r2) do
    if is_nil(r1.best) or is_nil(r2.best) do
      from_single(nil, 0.0)
    else
      %__MODULE__{
        min: r1.min * r2.min,
        best: r1.best * r2.best,
        max: r1.max * r2.max,
        confidence: r1.confidence * r2.confidence
      }
    end
  end

  @doc """
  Divides a range by a scalar value.

  ## Examples

      iex> r = Range.from_range(180, 200, 220, 0.9)
      iex> Range.divide(r, 4)
      %Range{min: 45.0, best: 50.0, max: 55.0, confidence: 0.9}
  """
  @spec divide(t(), number()) :: t()
  def divide(%__MODULE__{} = range, divisor) when is_number(divisor) and divisor != 0 do
    if is_nil(range.best) do
      range
    else
      float_divisor = to_float(divisor)

      %__MODULE__{
        min: range.min / float_divisor,
        best: range.best / float_divisor,
        max: range.max / float_divisor,
        confidence: range.confidence
      }
    end
  end

  def divide(%__MODULE__{} = range, _), do: range

  @doc """
  Sums a list of ranges.

  ## Examples

      iex> ranges = [Range.from_single(100), Range.from_single(50), Range.from_single(25)]
      iex> Range.sum_ranges(ranges)
      %Range{min: 175.0, best: 175.0, max: 175.0, confidence: 1.0}
  """
  @spec sum_ranges([t()]) :: t()
  def sum_ranges([]), do: from_single(0, 1.0)
  def sum_ranges([single]), do: single

  def sum_ranges(ranges) when is_list(ranges) do
    ranges
    |> Enum.filter(fn r -> not is_nil(r.best) end)
    |> case do
      [] -> from_single(0, 1.0)
      filtered -> Enum.reduce(filtered, &add/2)
    end
  end

  @doc """
  Applies confidence to widen a range.

  Lower confidence = wider range to account for uncertainty.
  A confidence of 1.0 leaves the range unchanged.
  A confidence of 0.5 doubles the spread from best.

  ## Examples

      iex> r = Range.from_range(90, 100, 110, 0.9)
      iex> Range.apply_confidence_spread(r, 0.5)
      # Widens the range to account for lower confidence
  """
  @spec apply_confidence_spread(t(), float()) :: t()
  def apply_confidence_spread(%__MODULE__{} = range, confidence)
      when is_float(confidence) and confidence > 0 do
    if is_nil(range.best) do
      %{range | confidence: confidence}
    else
      # Width factor: lower confidence = wider range
      width_factor = 1.0 + (1.0 - confidence) * 0.5

      # Calculate current spread from best
      low_spread = range.best - range.min
      high_spread = range.max - range.best

      # Apply width factor
      new_low_spread = low_spread * width_factor
      new_high_spread = high_spread * width_factor

      %__MODULE__{
        min: max(0, range.best - new_low_spread),
        best: range.best,
        max: range.best + new_high_spread,
        confidence: confidence
      }
    end
  end

  @doc """
  Rounds all values in the range to specified decimal places.
  """
  @spec round_range(t(), integer()) :: t()
  def round_range(%__MODULE__{} = range, decimals \\ 2) do
    if is_nil(range.best) do
      range
    else
      %__MODULE__{
        min: Float.round(range.min, decimals),
        best: Float.round(range.best, decimals),
        max: Float.round(range.max, decimals),
        confidence: Float.round(range.confidence, 3)
      }
    end
  end

  @doc """
  Converts a range to a map for JSON serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = range) do
    %{
      min: range.min,
      best: range.best,
      max: range.max,
      confidence: range.confidence
    }
  end

  # Private helpers

  defp to_float(value) when is_float(value), do: value
  defp to_float(value) when is_integer(value), do: value * 1.0
  defp to_float(%Decimal{} = value), do: Decimal.to_float(value)
  defp to_float(nil), do: nil
end
