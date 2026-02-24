defmodule Controlcopypasta.Ingredients.SubParsers.GarlicTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Ingredients.TokenParser

  describe "garlic sub-parser" do
    test "parses '1 head garlic, cloves peeled'" do
      result = TokenParser.parse("1 head garlic, cloves peeled")

      assert result.quantity == 1.0
      assert result.unit == "head"
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "garlic"
      assert "peeled" in result.preparations
    end

    test "parses '5 garlic cloves (about 1 tbsp), minced'" do
      result = TokenParser.parse("5 garlic cloves (about 1 tbsp), minced")

      assert result.quantity == 5.0
      assert result.unit == "clove"
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "garlic"
      assert "minced" in result.preparations
    end

    test "parses 'Cloves from 1 head of garlic'" do
      result = TokenParser.parse("Cloves from 1 head of garlic")

      assert result.quantity == 1.0
      assert result.unit == "head"
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "garlic"
    end

    test "parses 'Cloves from 1 head of garlic (about 8 cloves), smashed and peeled'" do
      result =
        TokenParser.parse("Cloves from 1 head of garlic (about 8 cloves), smashed and peeled")

      assert result.quantity == 1.0
      assert result.unit == "head"
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "garlic"
      assert "smashed" in result.preparations
      assert "peeled" in result.preparations
    end

    test "does not intercept simple '4 cloves garlic, minced' (standard parser handles it)" do
      result = TokenParser.parse("4 cloves garlic, minced")

      # Should still parse correctly (either via sub-parser or standard)
      assert result.quantity == 4.0
      assert result.unit == "clove"
      assert hd(result.ingredients).name == "garlic"
      assert "minced" in result.preparations
    end

    test "does not match '1 tsp whole cloves' (no garlic token)" do
      result = TokenParser.parse("1 tsp whole cloves")

      assert result.unit == "tsp"
      # Should not be confused with garlic
      names = Enum.map(result.ingredients, & &1.name)
      refute "garlic" in names
    end

    test "parses '3 garlic cloves, minced'" do
      result = TokenParser.parse("3 garlic cloves, minced")

      assert result.quantity == 3.0
      assert result.unit == "clove"
      assert hd(result.ingredients).name == "garlic"
      assert "minced" in result.preparations
    end
  end
end
