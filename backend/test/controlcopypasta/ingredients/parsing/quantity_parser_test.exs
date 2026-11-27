defmodule Controlcopypasta.Ingredients.Parsing.QuantityParserTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.Parsing.QuantityParser

  describe "parse/1 adds the parts of a mixed number" do
    test "a whole number and a proper fraction" do
      assert QuantityParser.parse(["1", "1/2"]) == {1.5, 1.5, 1.5}
      assert QuantityParser.parse(["2", "1/4"]) == {2.25, 2.25, 2.25}
    end

    test "a bare fraction or whole number stands alone" do
      assert QuantityParser.parse(["1/2"]) == {0.5, 0.5, 0.5}
      assert QuantityParser.parse(["3"]) == {3.0, 3.0, 3.0}
      assert QuantityParser.parse([]) == {nil, nil, nil}
    end
  end

  describe "parse/1 does not add numbers that are not a mixed number" do
    test "a second whole number is dropped" do
      # ["2", "1"] comes from `2 1 1/4"-thick steaks`: the "1" belongs to a
      # thickness, not to the count. Added, it made three steaks out of two.
      assert QuantityParser.parse(["2", "1"]) == {2.0, 2.0, 2.0}

      # ["4", "5"] came from "4 or 5 small red potatoes" -- nine potatoes.
      assert QuantityParser.parse(["4", "5"]) == {4.0, 4.0, 4.0}
    end

    test "a written number after the quantity is dropped" do
      # "1 1/2 cups dried chickpeas, soaked overnight or for six hours" read as
      # seven and a half cups.
      assert QuantityParser.parse(["1", "1/2", "six"]) == {1.5, 1.5, 1.5}

      # "1 1/2 cups half and half": "half" is a written 0.5.
      assert QuantityParser.parse(["1", "1/2", "half"]) == {1.5, 1.5, 1.5}
    end

    test "an improper fraction is not a mixed-number tail" do
      assert QuantityParser.parse(["2", "3/2"]) == {2.0, 2.0, 2.0}
    end

    test "a fraction after a dropped token is not reached" do
      # Dropping stops at the first token that is not a proper fraction, so
      # nothing further is added either.
      assert QuantityParser.parse(["2", "1", "1/2"]) == {2.0, 2.0, 2.0}
    end
  end

  describe "parse/1 ranges" do
    test "a dash range gives both bounds" do
      assert QuantityParser.parse(["1-2"]) == {1.5, 1.0, 2.0}
    end

    test "a fraction finishes the upper bound of a range" do
      assert QuantityParser.parse(["1-1", "1/2"]) == {1.25, 1.0, 1.5}
    end

    test "anything else after a range is dropped" do
      assert QuantityParser.parse(["1-2", "6"]) == {1.5, 1.0, 2.0}
    end
  end

  describe "parse_single/1" do
    test "decimals, fractions and written numbers" do
      assert QuantityParser.parse_single("2") == 2.0
      assert QuantityParser.parse_single("0.5") == 0.5
      assert QuantityParser.parse_single("3/4") == 0.75
      assert QuantityParser.parse_single("one") == 1.0
      assert QuantityParser.parse_single("1/0") == nil
      assert QuantityParser.parse_single("invalid") == nil
      assert QuantityParser.parse_single(nil) == nil
    end
  end
end
