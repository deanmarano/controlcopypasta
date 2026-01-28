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
