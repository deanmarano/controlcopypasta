defmodule Controlcopypasta.Ingredients.Detection.StatedWeightTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.Detection.StatedWeight

  describe "detect/1" do
    # Every fixture is a real stored line.
    test "reads a total weight" do
      assert %{quantity: 4.0, unit: "oz", scope: :total} =
               StatedWeight.detect("4 thin slices ham or prosciutto (about 4 oz. total)")
    end

    test "reads a bare weight as the total" do
      # No "total" written, but "6 medium leeks (about 1 lb.)" is a pound of
      # leeks, which is how the corpus uses this shape.
      assert %{quantity: 1.0, unit: "lb", scope: :total} =
               StatedWeight.detect("6 medium leeks (about 1 lb.), halved lengthwise")
    end

    test "reads a per-item weight as such" do
      assert %{quantity: 1.0, unit: "lb", scope: :each} =
               StatedWeight.detect("2 thick-cut boneless rib-eye steaks (about 1 lb. each)")
    end

    test "reads a mixed number with a vulgar fraction" do
      # "1½" must not match as a bare "1" with the fraction left over -- that
      # read this line as one pound instead of one and a half.
      assert %{quantity: 1.5, unit: "lb"} =
               StatedWeight.detect("4 skinless, boneless chicken breasts (about 1½ lb. total)")
    end

    test "reads a range, keeping the span" do
      assert %{quantity: 6.5, quantity_min: 6.0, quantity_max: 7.0, unit: "oz"} =
               StatedWeight.detect("20 jumbo shells (6-7 ounces)")

      assert %{quantity: 2.25, quantity_min: 2.0, quantity_max: 2.5, unit: "lb"} =
               StatedWeight.detect("1 very large or 2 small savoy cabbages (2–2½ lb. total)")
    end

    test "takes the author's unit when a metric restatement follows" do
      assert %{quantity: 2.0, unit: "lb"} =
               StatedWeight.detect("1 small head cauliflower (about 2 lb./907 g), cored")
    end

    test "ignores a parenthetical that is not purely a weight" do
      # Each of these has something else inside, so the weight is not the whole
      # story and guessing is worse than leaving it.
      for text <- [
            "8 ounces (1 1/2 cups; 225g) cubed fresh pineapple",
            "2 cups (packed; 100 g) light brown sugar",
            "1 bunch kale (about 10 oz.; stems removed)"
          ] do
        assert StatedWeight.detect(text) == nil, text
      end
    end

    test "ignores a line with no parenthetical weight" do
      assert StatedWeight.detect("2 cups flour") == nil
      assert StatedWeight.detect("Kosher salt") == nil
    end

    test "returns quickly on a parenthetical full of numbers" do
      # An earlier version applied the weight pattern to the whole line and
      # went into catastrophic backtracking on this shape, hanging the parse.
      text = "8 ounces (1 1/2 1/2 1/2 1/2 1/2 1/2 1/2 1/2 1/2 cups abcdefgh) pineapple"

      {micros, _} = :timer.tc(fn -> StatedWeight.detect(text) end)

      assert micros < 100_000, "took #{micros}us"
    end
  end
end
