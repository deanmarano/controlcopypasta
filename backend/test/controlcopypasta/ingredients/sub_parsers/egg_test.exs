defmodule Controlcopypasta.Ingredients.SubParsers.EggTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Ingredients.TokenParser

  describe "egg sub-parser — beaten with pattern" do
    test "parses '1 large egg, beaten with 1 tbsp milk'" do
      result = TokenParser.parse("1 large egg, beaten with 1 tbsp milk")

      assert result.quantity == 1.0
      assert result.unit == nil
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "egg"
      assert "beaten" in result.preparations
      # "with" should NOT appear as an ingredient
      names = Enum.map(result.ingredients, & &1.name)
      refute "with" in names
      refute "milk" in names
    end

    test "parses '2 eggs, beaten with a fork'" do
      result = TokenParser.parse("2 eggs, beaten with a fork")

      assert result.quantity == 2.0
      assert hd(result.ingredients).name == "egg"
      assert "beaten" in result.preparations
    end
  end

  describe "egg sub-parser — separated pattern" do
    test "parses '6 eggs, yolks and whites separated'" do
      result = TokenParser.parse("6 eggs, yolks and whites separated")

      assert result.quantity == 6.0
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "egg"
      assert "separated" in result.preparations
      # Should not have "yolks" or "whites" as separate ingredients
      names = Enum.map(result.ingredients, & &1.name)
      refute "yolks" in names
      refute "whites" in names
    end

    test "parses '4 large eggs, whites and yolks separated'" do
      result = TokenParser.parse("4 large eggs, whites and yolks separated")

      assert result.quantity == 4.0
      assert hd(result.ingredients).name == "egg"
      assert "separated" in result.preparations
    end
  end

  describe "egg sub-parser — plus pattern" do
    test "parses '1 egg plus 1 yolk'" do
      result = TokenParser.parse("1 egg plus 1 yolk")

      assert length(result.ingredients) == 2
      names = Enum.map(result.ingredients, & &1.name)
      assert "egg" in names
      assert "egg yolk" in names
    end

    test "parses '2 eggs plus 1 egg white'" do
      result = TokenParser.parse("2 eggs plus 1 egg white")

      assert length(result.ingredients) == 2
      names = Enum.map(result.ingredients, & &1.name)
      assert "egg" in names
      assert "egg white" in names
    end
  end

  describe "egg sub-parser — hard-boiled pattern" do
    test "parses '8 large eggs, hard-boiled and peeled'" do
      result = TokenParser.parse("8 large eggs, hard-boiled and peeled")

      assert result.quantity == 8.0
      assert length(result.ingredients) == 1
      assert hd(result.ingredients).name == "egg"
      assert "hard-boiled" in result.preparations
      assert "peeled" in result.preparations
    end

    test "parses '4 eggs, hard-boiled'" do
      result = TokenParser.parse("4 eggs, hard-boiled")

      assert result.quantity == 4.0
      assert hd(result.ingredients).name == "egg"
      assert "hard-boiled" in result.preparations
    end
  end

  describe "egg sub-parser — non-intercepted patterns" do
    test "simple '4 eggs' falls through to standard parser" do
      result = TokenParser.parse("4 eggs")

      assert result.quantity == 4.0
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "egg"))
    end

    test "simple '2 egg whites' falls through to standard parser" do
      result = TokenParser.parse("2 egg whites")

      assert result.quantity == 2.0
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "egg"))
    end

    test "'2 eggs, warmed' falls through to standard parser" do
      result = TokenParser.parse("2 eggs, warmed")

      assert result.quantity == 2.0
      assert "warmed" in result.preparations
    end
  end
end
