defmodule Controlcopypasta.Ingredients.ContainerSizeUnitTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.TokenParser

  @lookup %{
    "black beans" => {"black beans", "id-beans"},
    "tomato" => {"tomato", "id-tomato"},
    "chickpeas" => {"chickpeas", "id-chickpeas"},
    "milk" => {"milk", "id-milk"},
    "flour" => {"flour", "id-flour"},
    "tofu" => {"tofu", "id-tofu"}
  }

  defp parse(text), do: TokenParser.parse(text, lookup: @lookup)

  describe "a container that captured its own size does not also set the quantity unit" do
    test "every spelling of the size agrees" do
      # These differ only in how the ounces are written. The hyphenated form
      # always worked; the spaced forms used to leak "oz" into the unit, which
      # made the line mean one ounce of beans instead of one 15 oz can.
      for text <- [
            "1 (15 oz) can black beans",
            "1 (15 oz.) can black beans",
            "1 (15 ounce) can black beans",
            "1 (15-ounce) can black beans"
          ] do
        parsed = parse(text)

        assert parsed.quantity == 1.0, "wrong quantity for #{inspect(text)}"
        assert is_nil(parsed.unit), "#{inspect(text)} leaked unit #{inspect(parsed.unit)}"
        assert parsed.container.size_value == 15.0
        assert parsed.container.size_unit in ["oz", "oz."]
        assert parsed.container.container_type == "can"
      end
    end

    test "the count stays on the containers, not the ounces" do
      parsed = parse("2 (15 oz) cans chickpeas, rinsed")

      assert parsed.quantity == 2.0
      assert is_nil(parsed.unit)
      assert parsed.container.size_value == 15.0
    end

    test "jars and packages behave like cans" do
      for {text, type} <- [
            {"1 (24 ounce) jar marinara sauce", "jar"},
            {"1 (10 oz) package super firm tofu", "package"}
          ] do
        parsed = parse(text)

        assert is_nil(parsed.unit), "#{inspect(text)} leaked unit"
        assert parsed.container.container_type == type
      end
    end
  end

  describe "a parenthesised measurement that is the only one on the line is kept" do
    test "a weight with no container survives" do
      # Dropping this would leave a bare count with no density, and therefore
      # no nutrition at all for the line.
      # The real recipe line. Note the trailing sentence matters: with nothing
      # after the parenthesis the tokenizer labels "ounces" a :word rather than
      # a :unit, so the shorter form has no unit either way.
      parsed = parse("20 jumbo shells (6-7 ounces). You'll need 16, but some may fall apart")

      assert parsed.quantity == 20.0
      assert parsed.unit == "oz"
    end

    test "a container with no captured size keeps the parenthesised unit" do
      parsed = parse("1 can tomato sauce (14.5 oz / 400 grams)")

      assert parsed.container.container_type == "can"
      assert is_nil(parsed.container.size_value)
      assert parsed.unit == "oz"
    end

    test "a size given only in parentheses, with no container word" do
      parsed = parse("One (14- to 16- ounce) tub firm tofu")

      assert parsed.unit == "oz"
    end
  end

  describe "a real unit outside the parentheses still wins" do
    test "a metric equivalent does not replace the stated unit" do
      parsed = parse("1 cup (240 ml) milk")

      assert parsed.quantity == 1.0
      assert parsed.unit == "cup"
    end

    test "a gram equivalent does not replace the stated unit" do
      parsed = parse("2 cups (256 grams) flour")

      assert parsed.unit == "cup"
    end
  end
end
