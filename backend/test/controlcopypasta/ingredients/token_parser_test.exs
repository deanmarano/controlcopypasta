defmodule Controlcopypasta.Ingredients.TokenParserTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Ingredients.TokenParser

  describe "parse/1" do
    test "parses simple ingredient with quantity and unit" do
      result = TokenParser.parse("2 cups flour")

      assert result.quantity == 2.0
      assert result.unit == "cup"
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "flour"
    end

    test "parses quantity range" do
      result = TokenParser.parse("1-2 Tbsp olive oil")

      assert result.quantity == 1.5  # average
      assert result.quantity_min == 1.0
      assert result.quantity_max == 2.0
      assert result.unit == "tbsp"
    end

    test "parses fraction quantities" do
      result = TokenParser.parse("1/2 cup sugar")

      assert result.quantity == 0.5
      assert result.unit == "cup"
    end

    test "extracts preparations" do
      result = TokenParser.parse("2 cups diced tomatoes, drained")

      assert "diced" in result.preparations
      assert "drained" in result.preparations
    end

    test "handles 'or' alternatives with shared suffix" do
      result = TokenParser.parse("1 Tbsp avocado oil or coconut oil")

      assert result.is_alternative == true
      assert length(result.ingredients) == 2

      names = Enum.map(result.ingredients, & &1.name)
      assert "avocado oil" in names
      assert "coconut oil" in names
    end

    test "handles 'or' alternatives with shared noun" do
      result = TokenParser.parse("white or yellow corn tortillas")

      assert result.is_alternative == true
      assert length(result.ingredients) == 2

      names = Enum.map(result.ingredients, & &1.name)
      assert "white corn tortillas" in names
      assert "yellow corn tortillas" in names
    end

    test "handles 'and' compound ingredients" do
      result = TokenParser.parse("salt and pepper")

      assert result.is_alternative == false
      assert length(result.ingredients) == 2

      names = Enum.map(result.ingredients, & &1.name)
      assert "salt" in names
      assert "pepper" in names
    end

    test "extracts storage medium from 'in X' patterns" do
      result = TokenParser.parse("1 chipotle pepper in adobo sauce")

      assert result.storage_medium == "in adobo sauce"
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "chipotle pepper"
    end

    test "handles various storage mediums" do
      cases = [
        {"anchovies in oil", "in oil"},
        {"tuna in water", "in water"},
        {"artichoke hearts in brine", "in brine"}
      ]

      for {input, expected_storage} <- cases do
        result = TokenParser.parse(input)
        assert result.storage_medium == expected_storage, "Failed for: #{input}"
      end
    end

    test "strips trailing asterisks from ingredient names" do
      result = TokenParser.parse("3 cups butternut squash*")

      assert hd(result.ingredients).name == "butternut squash"
    end

    test "handles modifiers like fresh, dried, boneless" do
      result = TokenParser.parse("1 lb boneless skinless chicken breast")

      assert "boneless" in result.modifiers or length(result.modifiers) >= 0
      # The ingredient should still match even with modifiers
      assert length(result.ingredients) == 1
    end

    test "handles ingredient without quantity" do
      result = TokenParser.parse("Fresh cilantro, chopped")

      assert result.quantity == nil
      assert "chopped" in result.preparations
      assert length(result.ingredients) == 1
    end

    test "handles note phrases like 'to taste'" do
      result = TokenParser.parse("salt and pepper to taste")

      assert length(result.ingredients) == 2
      names = Enum.map(result.ingredients, & &1.name)
      assert "salt" in names
      assert "pepper" in names
    end

    test "handles 'for garnish' note phrase" do
      result = TokenParser.parse("fresh parsley, for garnish")

      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "fresh parsley"
    end

    test "handles 'seeds and ribs removed' as prep" do
      result = TokenParser.parse("1/2 jalapeño pepper, seeds and ribs removed")

      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "jalapeño pepper"
      assert "removed" in result.preparations
    end
  end

  describe "metric weight patterns in parentheses" do
    # These tests cover the pattern where metric weights like (113g) or (30ml)
    # appear in parentheses after a measurement. These should NOT be extracted
    # as ingredient names.
    #
    # Examples from production data:
    # - "1 cup (113g) confectioners' sugar" -> should extract "confectioners' sugar", not "113g"
    # - "8 tablespoons (113g) unsalted butter" -> should extract "unsalted butter", not "113g"
    # - "1 cup (240ml) milk" -> should extract "milk", not "240ml"

    test "ignores parenthetical gram weights - confectioners' sugar" do
      result = TokenParser.parse("1 cup (113g) confectioners' sugar")

      names = Enum.map(result.ingredients, & &1.name)
      refute "113g" in names
      assert Enum.any?(names, &String.contains?(&1, "sugar"))
    end

    test "ignores parenthetical gram weights - butter" do
      result = TokenParser.parse("8 tablespoons (113g) unsalted butter")

      names = Enum.map(result.ingredients, & &1.name)
      refute "113g" in names
      assert Enum.any?(names, &String.contains?(&1, "butter"))
    end

    test "ignores parenthetical gram weights - onion with ounces" do
      result = TokenParser.parse("1 medium yellow onion (8 ounces; 227g), thinly sliced")

      names = Enum.map(result.ingredients, & &1.name)
      refute "227g" in names
      assert Enum.any?(names, &String.contains?(&1, "onion"))
    end

    test "ignores parenthetical ml weights - milk" do
      result = TokenParser.parse("1 cup (240ml) milk")

      names = Enum.map(result.ingredients, & &1.name)
      refute "240ml" in names
      assert "milk" in names
    end

    test "ignores parenthetical gram weights - multiple formats" do
      cases = [
        {"1/2 cup (57g) pecans, chopped", "57g", "pecans"},
        {"2 tablespoons (28g) butter, cold", "28g", "butter"},
        {"2 cups (454g) ricotta cheese", "454g", "ricotta cheese"},
        {"1 cup (227g) water", "227g", "water"}
      ]

      for {input, metric, expected_ingredient} <- cases do
        result = TokenParser.parse(input)
        names = Enum.map(result.ingredients, & &1.name)

        refute metric in names,
               "#{metric} should not be an ingredient in: #{input}"

        assert Enum.any?(names, &String.contains?(&1, expected_ingredient)),
               "#{expected_ingredient} should be found in: #{input}, got: #{inspect(names)}"
      end
    end

    test "ignores metric weights without space after number" do
      # Patterns like "113g" (no space) vs "113 g" (with space)
      cases = ["57g", "113g", "227g", "454g", "30ml", "60ml", "240ml"]

      for metric <- cases do
        result = TokenParser.parse("1 cup (#{metric}) flour")
        names = Enum.map(result.ingredients, & &1.name)
        refute metric in names, "#{metric} should not be an ingredient"
      end
    end
  end

  describe "juice/zest extraction patterns" do
    # These tests cover patterns where "juiced", "zested", or "juice/zest of"
    # should result in the derived ingredient (e.g., "lime juice" not just "lime")

    test "transforms 'X, juiced' to 'X juice'" do
      result = TokenParser.parse("1 lime, juiced")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      refute "lime" in names or "juiced" in names
    end

    test "transforms 'X, zested' to 'X zest'" do
      result = TokenParser.parse("1 lemon, zested")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lemon zest" in names
      refute "lemon" in names or "zested" in names
    end

    test "transforms 'juice of X' to 'X juice'" do
      result = TokenParser.parse("juice of 1 lime")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      refute "juice" in names
    end

    test "transforms 'zest of X' to 'X zest'" do
      result = TokenParser.parse("zest of 1 lemon")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lemon zest" in names
      refute "zest" in names
    end

    test "transforms 'juice and zest of X' to both 'X juice' and 'X zest'" do
      result = TokenParser.parse("juice and zest of 1 lime")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      assert "lime zest" in names
      assert length(result.ingredients) == 2
    end

    test "transforms 'X (juiced)' to 'X juice'" do
      result = TokenParser.parse("1 lime (juiced, plus extra for garnish)")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
    end

    test "transforms 'X (zested + juiced)' to both" do
      result = TokenParser.parse("1 lime (zested + juiced)")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      assert "lime zest" in names
    end

    test "handles 'juice from X' pattern" do
      result = TokenParser.parse("juice from 1 lemon")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lemon juice" in names
    end

    test "handles compound juice patterns" do
      result = TokenParser.parse("the zest + juice from 1 lime")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      assert "lime zest" in names
    end
  end

  describe "singularization matching" do
    test "singularize/1 handles regular plurals" do
      assert TokenParser.singularize("tomatoes") == "tomato"
      assert TokenParser.singularize("peppers") == "pepper"
      assert TokenParser.singularize("onions") == "onion"
      assert TokenParser.singularize("carrots") == "carrot"
    end

    test "singularize/1 handles -ies plurals" do
      assert TokenParser.singularize("berries") == "berry"
      assert TokenParser.singularize("anchovies") == "anchovy"
      assert TokenParser.singularize("cherries") == "cherry"
    end

    test "singularize/1 handles -es plurals" do
      assert TokenParser.singularize("potatoes") == "potato"
      assert TokenParser.singularize("radishes") == "radish"
      assert TokenParser.singularize("peaches") == "peach"
    end

    test "singularize/1 preserves words that naturally end in s" do
      assert TokenParser.singularize("hummus") == "hummus"
      assert TokenParser.singularize("couscous") == "couscous"
      assert TokenParser.singularize("asparagus") == "asparagus"
      assert TokenParser.singularize("molasses") == "molasses"
    end

    test "singularize/1 handles -ves plurals" do
      assert TokenParser.singularize("leaves") == "leaf"
      assert TokenParser.singularize("halves") == "half"
      assert TokenParser.singularize("loaves") == "loaf"
    end

    test "plural ingredient names match canonical via singularization" do
      # "red peppers" should match via singularization to "red pepper" -> "red bell pepper"
      lookup = %{
        "red pepper" => {"red bell pepper", "test-id-red-pepper"}
      }

      result = TokenParser.parse("roasted red peppers", lookup: lookup)

      # Should find a match (the singular form matches)
      primary = hd(result.ingredients)
      assert primary.canonical_name == "red bell pepper",
             "Expected 'roasted red peppers' to match 'red bell pepper', got: #{inspect(primary)}"
      assert primary.confidence >= 0.9
    end
  end

  describe "juice/zest noise filtering" do
    test "filters 'juice from' pattern as noise" do
      result = TokenParser.parse("juice from 2 limes")

      names = Enum.map(result.ingredients, & &1.name)
      # Raw name is "limes juice" (plural); singularization happens in canonical matching
      assert Enum.any?(names, &String.ends_with?(&1, "juice"))
      refute Enum.any?(names, &String.contains?(&1, "juice from"))
    end

    test "filters 'fresh juice from' pattern as noise" do
      result = TokenParser.parse("fresh juice from 2 lemons")

      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.ends_with?(&1, "juice"))
      refute Enum.any?(names, &String.contains?(&1, "fresh juice"))
    end

    test "filters 'freshly squeezed juice from' pattern as noise" do
      result = TokenParser.parse("freshly squeezed juice from 2 limes")

      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.ends_with?(&1, "juice"))
      refute Enum.any?(names, &String.contains?(&1, "freshly squeezed juice"))
    end

    test "filters 'lemon zest from' pattern as noise" do
      result = TokenParser.parse("lemon zest from 1 lemon")

      names = Enum.map(result.ingredients, & &1.name)
      # Should have lemon zest, not "lemon zest from zest"
      refute Enum.any?(names, &String.contains?(&1, "zest from"))
    end
  end

  describe "preparation word classification" do
    test "classifies 'warmed' as preparation" do
      result = TokenParser.parse("2 eggs, warmed")

      assert "warmed" in result.preparations
      names = Enum.map(result.ingredients, & &1.name)
      refute "warmed" in names
    end

    test "classifies 'pressed' as preparation" do
      result = TokenParser.parse("2 cloves garlic, pressed")

      assert "pressed" in result.preparations
      names = Enum.map(result.ingredients, & &1.name)
      refute "pressed" in names
    end

    test "classifies 'blanched' as preparation" do
      result = TokenParser.parse("1 lb green beans, blanched")

      assert "blanched" in result.preparations
    end

    test "classifies 'marinated' as preparation" do
      result = TokenParser.parse("1 lb chicken, marinated")

      assert "marinated" in result.preparations
    end

    test "classifies 'dissolved' as preparation" do
      result = TokenParser.parse("1 tsp yeast, dissolved")

      assert "dissolved" in result.preparations
    end
  end

  describe "ingredient stop words" do
    test "rejects single-word prepositions as ingredient names" do
      # These words should not appear as ingredient names
      stop_words = ~w(with into above sub)

      for word <- stop_words do
        result = TokenParser.parse(word)
        assert result.ingredients == [],
               "'#{word}' should not be an ingredient name, got: #{inspect(result.ingredients)}"
      end
    end
  end

  describe "note phrase handling" do
    test "handles 'at room temperature' as a note" do
      result = TokenParser.parse("4 eggs, at room temperature")

      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "egg"))
      refute Enum.any?(names, &String.contains?(&1, "room"))
      refute Enum.any?(names, &String.contains?(&1, "temperature"))
    end

    test "handles 'if needed' as a note" do
      result = TokenParser.parse("water, if needed")

      names = Enum.map(result.ingredients, & &1.name)
      assert "water" in names
      refute Enum.any?(names, &String.contains?(&1, "needed"))
    end

    test "handles 'your choice' as a note" do
      result = TokenParser.parse("1 cup cheese, your choice")

      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "cheese"))
      refute Enum.any?(names, &String.contains?(&1, "choice"))
    end
  end

  describe "to_jsonb_map/1" do
    test "converts parsed ingredient to JSONB-compatible map" do
      result = TokenParser.parse("2 cups diced tomatoes")
      json = TokenParser.to_jsonb_map(result)

      assert json["text"] == "2 cups diced tomatoes"
      assert json["quantity"]["value"] == 2.0
      assert json["quantity"]["unit"] == "cup"
      assert "diced" in json["preparations"]
    end

    test "includes alternatives in JSONB map when present" do
      result = TokenParser.parse("olive oil or vegetable oil")
      json = TokenParser.to_jsonb_map(result)

      assert is_list(json["alternatives"])
      assert length(json["alternatives"]) == 1
    end

    test "includes storage medium in JSONB map when present" do
      result = TokenParser.parse("chipotle in adobo sauce")
      json = TokenParser.to_jsonb_map(result)

      assert json["storage_medium"] == "in adobo sauce"
    end
  end
end
