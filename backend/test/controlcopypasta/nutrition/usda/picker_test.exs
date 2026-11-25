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
      # 101 vs 276 kcal/100g, over 4,505 stored rows.
      assert {false, reason} =
               Picker.assess("thyme", [c("Thyme, fresh", 101.0), c("Spices, thyme, dried", 276.0)])

      assert reason =~ "fresh vs dried"
    end
  end

  describe "assess/2 accepts a genuine match" do
    test "an FDC category prefix is not a mismatch" do
      # "Cheese, cheddar" for cheddar: the prefix is FDC's category, not a
      # different food. This record carries slice = 17 g, the actual gap.
      assert {true, reason} = Picker.assess("cheddar", [c("Cheese, cheddar", 408.0)])
      assert reason =~ "Cheese, cheddar"
    end

    test "a preparation qualifier alone is benign" do
      assert {true, _} = Picker.assess("xanthan gum", [c("Xanthan gum, powder", 333.0)])
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
      for {a, b, expected} <- [
            {"Peas, raw", "Peas, cooked", "raw vs cooked"},
            {"Peas, sweetened", "Peas, unsweetened", "sweetened vs unsweetened"},
            {"Peas, salted", "Peas, unsalted", "salted vs unsalted"},
            {"Peas, canned", "Peas, frozen", "canned vs frozen"}
          ] do
        assert {false, reason} = Picker.assess("peas", [c(a), c(b)])
        assert reason =~ expected, "#{a} / #{b}"
      end
    end

    test "a shared qualifier is not a conflict" do
      assert {true, _} =
               Picker.assess("oregano", [c("Oregano, dried"), c("Oregano, dried, ground")])
    end
  end
end
