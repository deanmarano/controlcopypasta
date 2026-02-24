defmodule Controlcopypasta.Nutrition.RangeTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Nutrition.Range

  describe "from_single/2" do
    test "creates a range with equal min/best/max" do
      range = Range.from_single(100)

      assert range.min == 100.0
      assert range.best == 100.0
      assert range.max == 100.0
      assert range.confidence == 1.0
    end

    test "accepts custom confidence" do
      range = Range.from_single(100, 0.8)

      assert range.confidence == 0.8
    end

    test "handles nil values" do
      range = Range.from_single(nil, 0.5)

      assert range.min == nil
      assert range.best == nil
      assert range.max == nil
      assert range.confidence == 0.5
    end
  end

  describe "from_range/4" do
    test "creates a range with explicit min/best/max" do
      range = Range.from_range(90, 100, 110, 0.9)

      assert range.min == 90.0
      assert range.best == 100.0
      assert range.max == 110.0
      assert range.confidence == 0.9
    end
  end

  describe "from_value_with_variation/3" do
    test "creates a range from a value with percentage variation" do
      range = Range.from_value_with_variation(100, 0.15)

      assert_in_delta range.min, 85.0, 0.001
      assert range.best == 100.0
      assert_in_delta range.max, 115.0, 0.001
      assert range.confidence == 1.0
    end

    test "accepts custom confidence" do
      range = Range.from_value_with_variation(100, 0.1, 0.8)

      assert range.confidence == 0.8
    end
  end

  describe "add/2" do
    test "adds two ranges together" do
      r1 = Range.from_range(90, 100, 110, 0.9)
      r2 = Range.from_range(40, 50, 60, 0.8)

      result = Range.add(r1, r2)

      assert result.min == 130.0
      assert result.best == 150.0
      assert result.max == 170.0
      # Weighted average confidence
      assert_in_delta result.confidence, 0.867, 0.01
    end

    test "handles one nil range" do
      r1 = Range.from_range(90, 100, 110, 0.9)
      r2 = Range.from_single(nil, 0.0)

      result = Range.add(r1, r2)

      assert result.min == 90.0
      assert result.best == 100.0
      assert result.max == 110.0
    end

    test "handles both nil ranges" do
      r1 = Range.from_single(nil, 0.0)
      r2 = Range.from_single(nil, 0.0)

      result = Range.add(r1, r2)

      assert result.best == nil
    end
  end

  describe "multiply/2" do
    test "multiplies a range by a scalar" do
      range = Range.from_range(90, 100, 110, 0.9)

      result = Range.multiply(range, 2)

      assert result.min == 180.0
      assert result.best == 200.0
      assert result.max == 220.0
      assert result.confidence == 0.9
    end

    test "handles nil range" do
      range = Range.from_single(nil, 0.5)

      result = Range.multiply(range, 2)

      assert result.best == nil
    end
  end

  describe "multiply_ranges/2" do
    test "multiplies two ranges together" do
      qty = Range.from_range(5, 5.5, 6, 0.9)
      density = Range.from_range(28, 28.35, 29, 0.95)

      result = Range.multiply_ranges(qty, density)

      assert result.min == 140.0
      assert_in_delta result.best, 155.925, 0.01
      assert result.max == 174.0
      # Confidence is multiplied
      assert_in_delta result.confidence, 0.855, 0.01
    end

    test "returns nil range when either input is nil" do
      r1 = Range.from_single(nil, 0.0)
      r2 = Range.from_range(5, 5.5, 6, 0.9)

      result = Range.multiply_ranges(r1, r2)

      assert result.best == nil
    end
  end

  describe "divide/2" do
    test "divides a range by a scalar" do
      range = Range.from_range(180, 200, 220, 0.9)

      result = Range.divide(range, 4)

      assert result.min == 45.0
      assert result.best == 50.0
      assert result.max == 55.0
      assert result.confidence == 0.9
    end

    test "handles division by zero" do
      range = Range.from_range(90, 100, 110, 0.9)

      result = Range.divide(range, 0)

      # Returns unchanged range
      assert result.best == 100.0
    end
  end

  describe "sum_ranges/1" do
    test "sums a list of ranges" do
      ranges = [
        Range.from_single(100),
        Range.from_single(50),
        Range.from_single(25)
      ]

      result = Range.sum_ranges(ranges)

      assert result.min == 175.0
      assert result.best == 175.0
      assert result.max == 175.0
    end

    test "handles empty list" do
      result = Range.sum_ranges([])

      assert result.min == 0.0
      assert result.best == 0.0
      assert result.max == 0.0
    end

    test "handles single item" do
      range = Range.from_range(90, 100, 110, 0.9)

      result = Range.sum_ranges([range])

      assert result == range
    end

    test "filters out nil ranges" do
      ranges = [
        Range.from_single(100),
        Range.from_single(nil, 0.0),
        Range.from_single(50)
      ]

      result = Range.sum_ranges(ranges)

      assert result.best == 150.0
    end
  end

  describe "apply_confidence_spread/2" do
    test "widens range for lower confidence" do
      range = Range.from_range(90, 100, 110, 1.0)

      result = Range.apply_confidence_spread(range, 0.5)

      # Spread should be widened
      assert result.best == 100.0
      assert result.min < 90.0
      assert result.max > 110.0
      assert result.confidence == 0.5
    end

    test "leaves range unchanged for full confidence" do
      range = Range.from_range(90, 100, 110, 1.0)

      result = Range.apply_confidence_spread(range, 1.0)

      assert result.min == 90.0
      assert result.max == 110.0
    end
  end

  describe "round_range/2" do
    test "rounds all values" do
      range = Range.from_range(90.123, 100.456, 110.789, 0.9123)

      result = Range.round_range(range, 1)

      assert result.min == 90.1
      assert result.best == 100.5
      assert result.max == 110.8
      assert result.confidence == 0.912
    end
  end

  describe "to_map/1" do
    test "converts range to a map" do
      range = Range.from_range(90, 100, 110, 0.9)

      result = Range.to_map(range)

      assert result == %{
               min: 90.0,
               best: 100.0,
               max: 110.0,
               confidence: 0.9
             }
    end
  end
end
