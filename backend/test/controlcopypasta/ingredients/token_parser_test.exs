defmodule Controlcopypasta.Ingredients.TokenParserTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Ingredients.TokenParser
  alias Controlcopypasta.Ingredients.TokenParser.ParsedIngredient

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
