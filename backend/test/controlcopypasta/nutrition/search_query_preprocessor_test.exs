defmodule Controlcopypasta.Nutrition.SearchQueryPreprocessorTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Nutrition.SearchQueryPreprocessor

  describe "preprocess/1" do
    test "returns nil for nil input" do
      assert SearchQueryPreprocessor.preprocess(nil) == nil
    end

    test "returns empty string for empty input" do
      assert SearchQueryPreprocessor.preprocess("") == ""
    end

    test "removes markdown links with pipe syntax" do
      assert SearchQueryPreprocessor.preprocess("[pitas | https://example.com/recipe]") == "pitas"
      assert SearchQueryPreprocessor.preprocess("[favorite buns | https://www.example.com]") == "favorite buns"
    end

    test "removes standard markdown links" do
      assert SearchQueryPreprocessor.preprocess("[pitas](https://example.com/recipe)") == "pitas"
    end

    test "removes standalone URLs" do
      # Note: whitespace is normalized so double space becomes single
      assert SearchQueryPreprocessor.preprocess("check out https://example.com for more") == "check out for more"
    end

    test "removes HTML entities" do
      assert SearchQueryPreprocessor.preprocess("I&#8217;ve made it") == "Ive made it"
      # Note: whitespace is normalized so double space becomes single
      assert SearchQueryPreprocessor.preprocess("cookies &amp; cream") == "cookies cream"
    end

    test "removes dual unit patterns" do
      assert SearchQueryPreprocessor.preprocess("2 cups/256 grams all-purpose flour") == "all-purpose flour"
      assert SearchQueryPreprocessor.preprocess("1/2 cup/115 grams butter") == "butter"
      assert SearchQueryPreprocessor.preprocess("3/4 packed cup/3 ounces cheese") == "cheese"
    end

    test "removes leading quantities" do
      # "1 inch" is removed but "piece" is kept (it's a common measurement word)
      assert SearchQueryPreprocessor.preprocess("1 inch piece fresh ginger") == "piece fresh ginger"
      assert SearchQueryPreprocessor.preprocess("2-3 cups bell pepper") == "bell pepper"
      assert SearchQueryPreprocessor.preprocess("3 limes") == "limes"
      # "One 2-inch" is removed but "piece" is kept
      assert SearchQueryPreprocessor.preprocess("One 2-inch piece cinnamon") == "piece cinnamon"
    end

    test "removes parenthetical content" do
      assert SearchQueryPreprocessor.preprocess("butter (salted)") == "butter"
      assert SearchQueryPreprocessor.preprocess("sambal oelek (sriracha works, too)") == "sambal oelek"
      assert SearchQueryPreprocessor.preprocess("herbs ((such as basil))") == "herbs"
    end

    test "removes trailing notes" do
      assert SearchQueryPreprocessor.preprocess("salt, optional") == "salt"
      assert SearchQueryPreprocessor.preprocess("parsley, for garnish") == "parsley"
      assert SearchQueryPreprocessor.preprocess("chili flakes, to taste") == "chili flakes"
    end

    test "removes known brand names" do
      # Simple brand name removal
      assert SearchQueryPreprocessor.preprocess("Classico marinara sauce") == "marinara sauce"
      assert SearchQueryPreprocessor.preprocess("Heinz ketchup") == "ketchup"
      # Note: Multi-word brands work when properly spaced
      assert SearchQueryPreprocessor.preprocess("General Mills cereal") == "cereal"
    end

    test "normalizes whitespace" do
      assert SearchQueryPreprocessor.preprocess("  too   many   spaces  ") == "too many spaces"
    end

    test "handles complex real-world examples" do
      # From actual failed ingredients
      assert SearchQueryPreprocessor.preprocess("2 cups/256 grams all-purpose flour") == "all-purpose flour"
      assert SearchQueryPreprocessor.preprocess("3/4 packed cup/3 ounces coarsely grated extra-sharp Cheddar") == "coarsely grated extra-sharp Cheddar"
      # Note: parenthetical removal may leave space before comma, which gets normalized
      result = SearchQueryPreprocessor.preprocess("1/2 cup/115 grams unsalted butter (1 stick), melted and slightly cooled")
      assert String.contains?(result, "unsalted butter")
      assert String.contains?(result, "melted")
    end
  end

  describe "search_variations/2" do
    test "returns empty list for nil/empty input" do
      assert SearchQueryPreprocessor.search_variations(nil, nil) == []
      assert SearchQueryPreprocessor.search_variations("", nil) == []
    end

    test "returns preprocessed name first" do
      variations = SearchQueryPreprocessor.search_variations("fresh basil leaves", nil)
      assert List.first(variations) == "fresh basil leaves"
    end

    test "includes display_name when provided" do
      variations = SearchQueryPreprocessor.search_variations("fresh basil leaves", "basil")
      assert "basil" in variations
    end

    test "includes version without modifiers" do
      variations = SearchQueryPreprocessor.search_variations("fresh chopped basil", nil)
      assert "basil" in variations
    end

    test "removes duplicates" do
      variations = SearchQueryPreprocessor.search_variations("basil", "basil")
      # Should not have "basil" twice
      assert Enum.count(variations, fn v -> v == "basil" end) == 1
    end

    test "limits to 5 variations" do
      variations = SearchQueryPreprocessor.search_variations("very long complex ingredient name with many words", nil)
      assert length(variations) <= 5
    end

    test "handles all-purpose flour" do
      variations = SearchQueryPreprocessor.search_variations("all-purpose flour", nil)
      assert "all-purpose flour" in variations
      # "all-purpose" is not a common modifier, so it won't be stripped
      # But we should get "all-purpose" as first significant word pair
      assert length(variations) >= 1
    end

    test "handles compound ingredients" do
      variations = SearchQueryPreprocessor.search_variations("apple cider vinegar", nil)
      assert "apple cider vinegar" in variations
      assert "apple cider" in variations or "cider vinegar" in variations
    end
  end

  describe "equipment?/1" do
    test "returns true for equipment" do
      assert SearchQueryPreprocessor.equipment?("metal wooden toothpicks") == true
      assert SearchQueryPreprocessor.equipment?("8 inch skewers") == true
      assert SearchQueryPreprocessor.equipment?("baking sheet") == true
      assert SearchQueryPreprocessor.equipment?("parchment paper") == true
    end

    test "returns false for food" do
      assert SearchQueryPreprocessor.equipment?("chicken breast") == false
      assert SearchQueryPreprocessor.equipment?("olive oil") == false
      assert SearchQueryPreprocessor.equipment?("all-purpose flour") == false
    end

    test "handles nil input" do
      assert SearchQueryPreprocessor.equipment?(nil) == false
    end
  end
end
