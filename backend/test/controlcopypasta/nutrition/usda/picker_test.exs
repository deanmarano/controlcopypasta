defmodule Controlcopypasta.Nutrition.Usda.PickerTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Nutrition.Usda.Picker

  defp c(description, calories \\ 100.0) do
    %{description: description, calories_per_100g: calories}
  end

  describe "assess/2 rejects FoodData Central's wrong top hits" do
    # Every pair below is a real result from the live API, and every one of
    # these ranked FIRST for the canonical name on its left. An earlier version
    # of this gate accepted all four. Search rank is not evidence of identity.
    test "a top hit that names a different food" do
      for {name, description, missing} <- [
            {"xanthan gum", "Chewing gum", "xanthan"},
            {"shaoxing wine", "Vinegar, red wine", "shaoxing"},
            {"aleppo pepper", "Pepper, banana, raw", "aleppo"}
          ] do
        assert {false, reason} = Picker.assess(name, [c(description)])
        assert reason =~ missing, name
      end
    end

    test "a top hit that is a different food from the same plant" do
      # Both ranked first and both were accepted by an earlier version of this
      # gate, which treated "oil" and "ground" as harmless category words.
      assert {false, reason} = Picker.assess("walnut", [c("Oil, walnut", 884.0)])
      assert reason =~ "oil"

      # The stored lines ask for sage by the leaf and the bunch -- the fresh
      # herb, not the dried ground spice.
      assert {false, reason} = Picker.assess("sage", [c("Spices, sage, ground", 315.0)])
      assert reason =~ "ground"
    end

    test "a top hit that names our food and then something else" do
      # "Cabbage, kimchi" ranked above "Cabbage, raw" -- and it is the raw
      # record that carries the "head, medium = 908 g" portion we need.
      assert {false, reason} =
               Picker.assess("cabbage", [c("Cabbage, kimchi", 15.0), c("Cabbage, raw", 25.0)])

      assert reason =~ "kimchi"
    end

    test "a top hit missing a qualifier that changes the food" do
      # "Sugars, brown" is right for brown sugar generally, but light vs dark
      # is a distinction the canonical name makes and the record does not.
      assert {false, reason} = Picker.assess("light brown sugar", [c("Sugars, brown", 380.0)])
      assert reason =~ "light"
    end

    test "the fresh-vs-dried case" do
      # 101 vs 276 kcal/100g, over 4,505 stored rows. Held because our name
      # says neither, so there is a real choice to make.
      assert {false, reason} =
               Picker.assess("thyme", [c("Thyme, fresh", 101.0), c("Spices, thyme, dried", 276.0)])

      assert reason =~ "fresh"
    end
  end

  describe "assess/2 accepts a genuine match" do
    test "an FDC category prefix is not a mismatch" do
      # "Cheese, cheddar" for cheddar: the prefix is FDC's category, not a
      # different food. This record carries slice = 17 g, the actual gap.
      assert {true, reason} = Picker.assess("cheddar", [c("Cheese, cheddar", 408.0)])
      assert reason =~ "Cheese, cheddar"
    end

    test "a category prefix and the plain form are benign" do
      assert {true, _} = Picker.assess("radicchio", [c("Radicchio, raw", 23.0)])
      assert {true, _} = Picker.assess("cardamom", [c("Spices, cardamom", 311.0)])
    end

    test "our own name may carry the qualifier" do
      # "whole milk ricotta" asks for exactly this record.
      assert {true, _} =
               Picker.assess("whole milk ricotta", [c("Cheese, ricotta, whole milk", 157.0)])
    end

    test "plural and singular are treated as the same word" do
      assert {true, _} = Picker.assess("black peppercorn", [c("Peppercorns, black", 251.0)])
    end
  end

  describe "assess/2 basics" do
    test "refuses when there is nothing to pick" do
      assert {false, "no candidates"} = Picker.assess("anything", [])
    end

    test "refuses a candidate with no calorie value" do
      # Without calories the row would make the ingredient look covered while
      # contributing nothing to the total.
      assert {false, reason} = Picker.assess("cheddar", [c("Cheese, cheddar", nil)])
      assert reason =~ "no calorie value"
    end

    test "catches each opposing group" do
      # Each of these is rejected; which rule catches it depends on whether the
      # qualifier is a plain form ("raw") or a real modification ("canned"),
      # and either way a human decides.
      for {a, b} <- [
            {"Peas, raw", "Peas, cooked"},
            {"Peas, sweetened", "Peas, unsweetened"},
            {"Peas, salted", "Peas, unsalted"},
            {"Peas, canned", "Peas, frozen"}
          ] do
        assert {false, _reason} = Picker.assess("peas", [c(a), c(b)])
      end
    end

    test "our own name may carry a state qualifier" do
      # "dried oregano" asks for the dried record, so it is not an unexplained
      # addition. Bare "oregano" with the same candidate is held, above.
      assert {true, _} =
               Picker.assess("dried oregano", [c("Oregano, dried"), c("Spices, oregano, dried")])
    end
  end
end
