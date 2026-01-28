defmodule Controlcopypasta.Ingredients.SubParsers.CitrusTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Ingredients.TokenParser

  describe "citrus sub-parser" do
    test "parses 'juice from 2 limes'" do
      result = TokenParser.parse("juice from 2 limes")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      assert result.quantity == 2.0
      # No "juice from juice" artifact
      refute Enum.any?(names, &String.contains?(&1, "juice from"))
    end

    test "parses 'freshly squeezed lemon juice from 2 lemons'" do
      result = TokenParser.parse("freshly squeezed lemon juice from 2 lemons")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lemon juice" in names
      assert result.quantity == 2.0
      refute Enum.any?(names, &String.contains?(&1, "squeezed"))
    end

    test "parses 'lemon zest from 1 lemon'" do
      result = TokenParser.parse("lemon zest from 1 lemon")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lemon zest" in names
      assert result.quantity == 1.0
      # No "zest from zest" artifact
      refute Enum.any?(names, &String.contains?(&1, "zest from"))
    end

    test "parses 'juice and zest of 1 lime'" do
      result = TokenParser.parse("juice and zest of 1 lime")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      assert "lime zest" in names
      assert length(result.ingredients) == 2
    end

    test "parses '1 lime, juiced'" do
      result = TokenParser.parse("1 lime, juiced")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      assert result.quantity == 1.0
    end

    test "parses 'the zest + juice from 1 lime'" do
      result = TokenParser.parse("the zest + juice from 1 lime")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      assert "lime zest" in names
    end

    test "parses '1 lemon, zested'" do
      result = TokenParser.parse("1 lemon, zested")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lemon zest" in names
      assert result.quantity == 1.0
    end

    test "parses '2 tbsp lemon juice'" do
      result = TokenParser.parse("2 tbsp lemon juice")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lemon juice" in names
      assert result.quantity == 2.0
      assert result.unit == "tbsp"
    end

    test "parses '1 lime (zested + juiced)'" do
      result = TokenParser.parse("1 lime (zested + juiced)")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
      assert "lime zest" in names
    end

    test "does not match non-citrus juice like 'pomegranate juice'" do
      result = TokenParser.parse("1 cup pomegranate juice")

      # Should fall through to standard parser
      names = Enum.map(result.ingredients, & &1.name)
      # "pomegranate" is not citrus, so citrus sub-parser should not match
      refute Enum.any?(names, &String.contains?(&1, "lime"))
    end

    test "handles 'juice of 1 lime'" do
      result = TokenParser.parse("juice of 1 lime")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lime juice" in names
    end

    test "handles 'zest of 1 lemon'" do
      result = TokenParser.parse("zest of 1 lemon")

      names = Enum.map(result.ingredients, & &1.name)
      assert "lemon zest" in names
    end

    test "handles orange juice pattern" do
      result = TokenParser.parse("juice from 1 orange")

      names = Enum.map(result.ingredients, & &1.name)
      assert "orange juice" in names
    end

    test "handles grapefruit zest pattern" do
      result = TokenParser.parse("1 grapefruit, zested")

      names = Enum.map(result.ingredients, & &1.name)
      assert "grapefruit zest" in names
    end
  end
end
