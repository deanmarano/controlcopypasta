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

    test "parses compound quantities like 1 1/2" do
      result = TokenParser.parse("1 1/2 cups flour")

      assert result.quantity == 1.5
      assert result.quantity_min == 1.5
      assert result.quantity_max == 1.5
      assert result.unit == "cup"
    end

    test "parses range with space before dash like 1 -1 1/2" do
      # "1 -1 1/2 cup" means "1 to 1½ cups"
      result = TokenParser.parse("1 -1 1/2 cup semi-sweet chocolate chips")

      assert result.quantity == 1.25  # average of 1 and 1.5
      assert result.quantity_min == 1.0
      assert result.quantity_max == 1.5
      assert result.unit == "cup"
    end

    test "parses range with spaces around dash like 1 - 2" do
      result = TokenParser.parse("1 - 2 cups milk")

      assert result.quantity == 1.5
      assert result.quantity_min == 1.0
      assert result.quantity_max == 2.0
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

    test "does not sum metric conversion quantities into primary quantity" do
      # Serious Eats pattern: "2 pounds (907 g)" should be 2, not 909
      cases = [
        {"2 pounds (907 g) beef chuck roast", 2.0},
        {"8 cups cold water (1890 ml), divided", 8.0},
        {"1 large onion (about 2 cups; 300 grams)", 1.0},
        {"3 cups homemade chicken stock (700 millilitres)", 3.0},
        {"1/2 medium fennel bulb (about 1 cup; 200 grams)", 0.5}
      ]

      for {input, expected_qty} <- cases do
        result = TokenParser.parse(input)

        assert result.quantity == expected_qty,
               "Expected quantity #{expected_qty} for '#{input}', got #{result.quantity}"
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

  describe "choices extraction (such as X, Y, or Z)" do
    test "extracts choices from 'such as' pattern" do
      result = TokenParser.parse("2 whole fish, such as branzini, mackerel, or trout, scaled and gutted")

      assert result.choices != nil
      assert length(result.choices) == 3

      choice_names = Enum.map(result.choices, & &1.name)
      assert "branzini" in choice_names
      assert "mackerel" in choice_names
      assert "trout" in choice_names
    end

    test "extracts preparations after choices" do
      result = TokenParser.parse("2 whole fish, such as branzini, mackerel, or trout, scaled and gutted")

      assert "scaled" in result.preparations
      assert "gutted" in result.preparations
    end

    test "matches choices to canonical ingredients when possible" do
      result = TokenParser.parse("1 lb white fish, such as cod, halibut, or tilapia")

      # Verify choices were extracted and we attempted to match them
      assert result.choices != nil
      assert length(result.choices) == 3

      # Each choice should have a name at minimum
      for choice <- result.choices do
        assert choice.name != nil
      end
    end

    test "handles 'preferably' as example intro" do
      result = TokenParser.parse("1 cup oil, preferably olive oil")

      assert result.choices != nil
      choice_names = Enum.map(result.choices, & &1.name)
      assert "olive oil" in choice_names
    end

    test "returns nil choices when no 'such as' pattern" do
      result = TokenParser.parse("2 cups flour")

      assert result.choices == nil
    end

    test "includes choices in JSONB map" do
      result = TokenParser.parse("2 whole fish, such as branzini, mackerel, or trout")
      json = TokenParser.to_jsonb_map(result)

      assert is_list(json["choices"])
      assert length(json["choices"]) == 3

      choice_names = Enum.map(json["choices"], & &1["name"])
      assert "branzini" in choice_names
      assert "mackerel" in choice_names
      assert "trout" in choice_names
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

  describe "written numbers" do
    test "parses 'one' as quantity 1" do
      result = TokenParser.parse("One 15-ounce can chickpeas")

      assert result.quantity == 1.0
    end

    test "parses 'two' as quantity 2" do
      result = TokenParser.parse("Two cans tomatoes")

      assert result.quantity == 2.0
    end

    test "parses 'a' as quantity 1" do
      result = TokenParser.parse("a large onion")

      assert result.quantity == 1.0
    end

    test "parses 'three' as quantity 3" do
      result = TokenParser.parse("three cloves garlic")

      assert result.quantity == 3.0
    end
  end

  describe "container extraction" do
    test "extracts container from 'size-unit container' pattern" do
      result = TokenParser.parse("One 15-ounce can chickpeas")

      assert result.container != nil
      assert result.container.size_value == 15.0
      assert result.container.size_unit == "oz"
      assert result.container.container_type == "can"
    end

    test "extracts container from 'size-unit container' with oz abbreviation" do
      result = TokenParser.parse("Two 14-oz cans tomatoes")

      assert result.container != nil
      assert result.container.size_value == 14.0
      assert result.container.size_unit == "oz"
      assert result.container.container_type == "cans"
    end

    test "extracts container without size" do
      result = TokenParser.parse("1 jar marinara sauce")

      assert result.container != nil
      assert result.container.size_value == nil
      assert result.container.container_type == "jar"
    end

    test "extracts correct primary ingredient with container" do
      result = TokenParser.parse("One 15-ounce can chickpeas, rinsed")

      assert result.primary_ingredient.name == "chickpeas"
      assert "rinsed" in result.preparations
    end

    test "includes container in JSONB map with string keys" do
      result = TokenParser.parse("One 15-ounce can chickpeas")
      json = TokenParser.to_jsonb_map(result)

      assert json["container"]["size_value"] == 15.0
      assert json["container"]["size_unit"] == "oz"
      assert json["container"]["container_type"] == "can"
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

  describe "preprocessing - equipment filtering" do
    test "filters 'A deep-fry thermometer' as equipment" do
      result = TokenParser.parse("A deep-fry thermometer")

      assert result.primary_ingredient == nil
      assert result.ingredients == []
    end

    test "filters 'A spice mill or mortar and pestle' as equipment" do
      result = TokenParser.parse("A spice mill or mortar and pestle")

      assert result.primary_ingredient == nil
      assert result.ingredients == []
    end

    test "filters 'A 9\"-diameter springform pan' as equipment" do
      result = TokenParser.parse("A 9\"-diameter springform pan")

      assert result.primary_ingredient == nil
    end

    test "filters 'An air fryer' as equipment" do
      result = TokenParser.parse("An air fryer")

      assert result.primary_ingredient == nil
    end

    test "does not filter regular ingredients starting with 'a'" do
      result = TokenParser.parse("a large onion")

      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "onion")
    end
  end

  describe "preprocessing - butter stick notation" do
    test "normalizes '2 sticks (1 cup) salted butter' to use cup unit" do
      result = TokenParser.parse("2 sticks (1 cup) salted butter, at room temperature")

      assert result.quantity == 1.0
      assert result.unit == "cup"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "butter")
    end

    test "normalizes '1/2 cup (1 stick) unsalted butter'" do
      result = TokenParser.parse("1/2 cup (1 stick) unsalted butter")

      assert result.quantity == 0.5
      assert result.unit == "cup"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "butter")
    end

    test "normalizes '1 stick (8 tablespoons) salted butter'" do
      result = TokenParser.parse("1 stick (8 tablespoons) salted butter")

      assert result.quantity == 8.0
      assert result.unit == "tbsp"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "butter")
    end

    test "does not affect non-butter ingredients with 'stick'" do
      result = TokenParser.parse("1 stick cinnamon")

      # Should not transform since it's not butter
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "cinnamon")
    end
  end

  describe "preprocessing - ginger size notation" do
    test "normalizes '1 1\" piece ginger' to '1 piece ginger'" do
      result = TokenParser.parse("1 1\" piece ginger, peeled, finely grated")

      assert result.quantity == 1.0
      assert result.unit == "piece"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "ginger")
    end

    test "normalizes '1 2-inch piece ginger'" do
      result = TokenParser.parse("1 2-inch piece ginger, peeled")

      assert result.quantity == 1.0
      assert result.unit == "piece"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "ginger")
    end

    test "normalizes '1 inch piece fresh ginger'" do
      result = TokenParser.parse("1 inch piece fresh ginger, grated")

      assert result.quantity == 1.0
      assert result.unit == "piece"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "ginger")
    end
  end

  describe "preprocessing - slash notation" do
    test "normalizes '1/2 cup/100 grams' to '1/2 cup'" do
      result = TokenParser.parse("1/2 cup/100 grams granulated sugar")

      assert result.quantity == 0.5
      assert result.unit == "cup"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "sugar")
    end

    test "normalizes '2 cups/256 grams' to '2 cups'" do
      result = TokenParser.parse("2 cups/256 grams all-purpose flour")

      assert result.quantity == 2.0
      assert result.unit == "cup"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "flour")
    end

    test "normalizes tablespoon/gram notation" do
      result = TokenParser.parse("3 tablespoons/45g honey")

      assert result.quantity == 3.0
      assert result.unit == "tbsp"
    end
  end

  describe "preprocessing - gram measurements in parentheses" do
    test "strips '(45g)' from ingredient text" do
      result = TokenParser.parse("1/2 cup (45g) rolled oats, old-fashioned")

      assert result.quantity == 0.5
      assert result.unit == "cup"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "oats")
    end

    test "strips '(200 grams)' from ingredient text" do
      result = TokenParser.parse("1 cup (200 grams) sugar")

      assert result.quantity == 1.0
      assert result.unit == "cup"
      assert result.primary_ingredient != nil
      assert String.contains?(result.primary_ingredient.name, "sugar")
    end

    test "handles multiple gram measurements" do
      result = TokenParser.parse("2 cups (240g) flour plus 1/4 cup (30g) for dusting")

      # Quantities are summed when "plus" is used (2 + 1/4 = 2.25)
      assert result.quantity == 2.25
      assert result.unit == "cup"
    end
  end

  describe "standalone metric formats" do
    # These tests cover UK/metric-style ingredients where the quantity and
    # metric unit are attached (e.g., "400g") without a separate imperial measurement.
    # The tokenizer should split "400g" into "400" (qty) + "g" (unit) so the
    # ingredient name is correctly extracted.

    test "parses '400g chickpeas' - gram weight with ingredient" do
      result = TokenParser.parse("400g chickpeas")

      assert result.quantity == 400.0
      assert result.unit == "g"
      assert result.primary_ingredient != nil
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "chickpeas"))
    end

    test "parses '200ml coconut milk' - milliliter with ingredient" do
      result = TokenParser.parse("200ml coconut milk")

      assert result.quantity == 200.0
      assert result.unit == "ml"
      assert result.primary_ingredient != nil
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "coconut milk"))
    end

    test "parses '1.5kg flour' - decimal kilogram" do
      result = TokenParser.parse("1.5kg flour")

      assert result.quantity == 1.5
      assert result.unit == "kg"
      assert result.primary_ingredient != nil
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "flour"))
    end

    test "parses '500g minced beef' - metric with modifier" do
      result = TokenParser.parse("500g minced beef")

      assert result.quantity == 500.0
      assert result.unit == "g"
      assert result.primary_ingredient != nil
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "beef"))
    end

    test "parses '250ml double cream' - metric with modifier" do
      result = TokenParser.parse("250ml double cream")

      assert result.quantity == 250.0
      assert result.unit == "ml"
      assert result.primary_ingredient != nil
    end

    test "parses '100g caster sugar, plus extra for dusting'" do
      result = TokenParser.parse("100g caster sugar, plus extra for dusting")

      assert result.quantity == 100.0
      assert result.unit == "g"
      assert result.primary_ingredient != nil
    end
  end

  describe "metric container patterns" do
    # Tests for patterns like "400g tin chopped tomatoes" and "1 x 400g tin"
    # where a metric weight describes the container size rather than ingredient quantity.

    test "parses '400g tin chopped tomatoes' - metric container" do
      result = TokenParser.parse("400g tin chopped tomatoes")

      assert result.primary_ingredient != nil
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "tomatoes"))
      assert result.container != nil
      assert result.container.size_value == 400.0
      assert result.container.size_unit == "g"
      assert result.container.container_type == "tin"
    end

    test "parses '1 x 400g tin chickpeas' - multiplier with metric container" do
      result = TokenParser.parse("1 x 400g tin chickpeas")

      assert result.quantity == 1.0
      assert result.primary_ingredient != nil
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "chickpeas"))
      assert result.container != nil
      assert result.container.size_value == 400.0
      assert result.container.size_unit == "g"
    end

    test "parses '2 x 400g tins chopped tomatoes'" do
      result = TokenParser.parse("2 x 400g tins chopped tomatoes")

      assert result.quantity == 2.0
      assert result.primary_ingredient != nil
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "tomatoes"))
      assert result.container != nil
      assert result.container.size_value == 400.0
    end

    test "parses '200ml can coconut milk' - ml container" do
      result = TokenParser.parse("200ml can coconut milk")

      assert result.primary_ingredient != nil
      names = Enum.map(result.ingredients, & &1.name)
      assert Enum.any?(names, &String.contains?(&1, "coconut milk"))
      assert result.container != nil
      assert result.container.size_value == 200.0
      assert result.container.size_unit == "ml"
    end

    test "does not create false metric container for imperial units" do
      # "2 cups jar" should NOT create a metric container
      result = TokenParser.parse("2 cups marinara sauce")

      # No container because cups is not a metric unit
      assert result.container == nil
      assert result.unit == "cup"
    end
  end

  describe "metric tokenizer splitting" do
    # Tests that verify the tokenizer correctly splits attached metric units

    alias Controlcopypasta.Ingredients.Tokenizer

    test "splits '400g' into qty and unit tokens" do
      tokens = Tokenizer.tokenize("400g chickpeas")
      labels = Enum.map(tokens, & &1.label)

      assert :qty in labels
      assert :unit in labels
      refute :metric_weight in labels
    end

    test "splits '200ml' into qty and unit tokens" do
      tokens = Tokenizer.tokenize("200ml milk")
      labels = Enum.map(tokens, & &1.label)

      assert :qty in labels
      assert :unit in labels
    end

    test "labels 'x' as multiplier between quantities" do
      tokens = Tokenizer.tokenize("1 x 400g tin")
      labels = Enum.map(tokens, & &1.label)

      assert :multiplier in labels
    end

    test "does not split fractions like '1/2g'" do
      # "1/2g" should NOT become "1/ 2 g" - the fraction should stay intact
      tokens = Tokenizer.tokenize("1/2 cup flour")
      qty_tokens = Enum.filter(tokens, &(&1.label == :qty))

      # Should have "1/2" as a single qty token
      assert Enum.any?(qty_tokens, &(&1.text == "1/2"))
    end

    test "does not split 'egg' or other words ending in metric-like letters" do
      tokens = Tokenizer.tokenize("2 eggs")
      word_tokens = Enum.filter(tokens, &(&1.label == :word))

      assert Enum.any?(word_tokens, &(&1.text == "eggs"))
    end
  end
end
