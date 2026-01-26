defmodule Controlcopypasta.Ingredients.ParserTest do
  use Controlcopypasta.DataCase

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.Parser
  alias Controlcopypasta.Ingredients.Parser.ParsedIngredient

  describe "parse/1 basic quantities" do
    test "parses integer quantities" do
      result = Parser.parse("2 cups flour", match_canonical: false)
      assert result.quantity == 2.0
      assert result.unit == "cup"
      assert result.raw_name == "flour"
    end

    test "parses decimal quantities" do
      result = Parser.parse("1.5 cups milk", match_canonical: false)
      assert result.quantity == 1.5
      assert result.unit == "cup"
    end

    test "parses fraction quantities" do
      result = Parser.parse("1/2 cup sugar", match_canonical: false)
      assert result.quantity == 0.5
      assert result.unit == "cup"
    end

    test "parses mixed number quantities" do
      result = Parser.parse("1 1/2 cups flour", match_canonical: false)
      assert result.quantity == 1.5
      assert result.unit == "cup"
    end

    test "parses mixed numbers with hyphen" do
      result = Parser.parse("1-1/2 cups flour", match_canonical: false)
      assert result.quantity == 1.5
      assert result.unit == "cup"
    end

    test "parses range quantities as average" do
      result = Parser.parse("2-3 cups flour", match_canonical: false)
      assert result.quantity == 2.5
      assert result.unit == "cup"
    end

    test "handles no quantity" do
      result = Parser.parse("salt to taste", match_canonical: false)
      assert result.quantity == nil
      assert result.raw_name == "salt to taste"
    end
  end

  describe "parse/1 unicode fractions" do
    test "parses unicode half" do
      result = Parser.parse("½ cup butter", match_canonical: false)
      assert result.quantity == 0.5
      assert result.unit == "cup"
    end

    test "parses unicode quarter" do
      result = Parser.parse("¼ tsp salt", match_canonical: false)
      assert result.quantity == 0.25
      assert result.unit == "tsp"
    end

    test "parses unicode three-quarters" do
      result = Parser.parse("¾ cup milk", match_canonical: false)
      assert result.quantity == 0.75
      assert result.unit == "cup"
    end

    # Regression: NYT Cooking uses "1½" (number directly followed by unicode fraction)
    test "parses integer followed by unicode half" do
      result = Parser.parse("1½ cups yellow split peas", match_canonical: false)
      assert result.quantity == 1.5
      assert result.unit == "cup"
    end

    test "parses integer followed by unicode quarter" do
      result = Parser.parse("2¼ cups flour", match_canonical: false)
      assert result.quantity == 2.25
      assert result.unit == "cup"
    end

    test "parses integer followed by unicode third" do
      result = Parser.parse("1⅓ cups sugar", match_canonical: false)
      assert result.quantity == 1.333
      assert result.unit == "cup"
    end
  end

  describe "parse/1 unit normalization" do
    test "normalizes tablespoons" do
      assert Parser.parse("2 tablespoons oil", match_canonical: false).unit == "tbsp"
      assert Parser.parse("2 tbsp oil", match_canonical: false).unit == "tbsp"
      assert Parser.parse("2 tbs oil", match_canonical: false).unit == "tbsp"
    end

    test "normalizes teaspoons" do
      assert Parser.parse("1 teaspoon salt", match_canonical: false).unit == "tsp"
      assert Parser.parse("1 tsp salt", match_canonical: false).unit == "tsp"
    end

    test "normalizes cups" do
      assert Parser.parse("2 cups flour", match_canonical: false).unit == "cup"
      assert Parser.parse("2 c flour", match_canonical: false).unit == "cup"
    end

    test "normalizes pounds" do
      assert Parser.parse("1 pound chicken", match_canonical: false).unit == "lb"
      assert Parser.parse("1 lb chicken", match_canonical: false).unit == "lb"
      assert Parser.parse("2 lbs chicken", match_canonical: false).unit == "lb"
    end

    test "normalizes ounces" do
      assert Parser.parse("4 ounces cheese", match_canonical: false).unit == "oz"
      assert Parser.parse("4 oz cheese", match_canonical: false).unit == "oz"
    end
  end

  describe "parse/1 container patterns" do
    test "parses container with size" do
      result = Parser.parse("2 (14.5 oz) cans diced tomatoes", match_canonical: false)
      assert result.quantity == 2.0
      assert result.unit == "can"
      assert result.container == %{size_value: 14.5, size_unit: "oz"}
      assert "diced" in result.preparations
    end

    test "parses metric container sizes" do
      result = Parser.parse("1 (400g) can chickpeas", match_canonical: false)
      assert result.quantity == 1.0
      assert result.unit == "can"
      assert result.container == %{size_value: 400.0, size_unit: "g"}
    end

    test "parses decimal container sizes" do
      result = Parser.parse("2 (28 oz) cans crushed tomatoes", match_canonical: false)
      assert result.quantity == 2.0
      assert result.container == %{size_value: 28.0, size_unit: "oz"}
    end
  end

  describe "parse/1 preparation extraction" do
    test "extracts single preparation" do
      result = Parser.parse("1 lb chicken breast, diced", match_canonical: false)
      assert "diced" in result.preparations
      assert result.raw_name == "chicken breast"
    end

    test "extracts multiple preparations" do
      result = Parser.parse("2 cans diced tomatoes, drained and rinsed", match_canonical: false)
      assert "diced" in result.preparations
      assert "drained" in result.preparations
      assert "rinsed" in result.preparations
    end

    test "extracts preparations from ingredient name" do
      result = Parser.parse("1 cup shredded cheese", match_canonical: false)
      assert "shredded" in result.preparations
      assert result.raw_name == "cheese"
    end

    test "extracts preparations with aliases" do
      result = Parser.parse("2 cups cubed potatoes", match_canonical: false)
      # "cubed" should map to "diced"
      assert "diced" in result.preparations
    end

    test "extracts temperature preparations" do
      result = Parser.parse("1/2 cup butter, softened", match_canonical: false)
      assert "softened" in result.preparations
    end

    test "extracts processing preparations" do
      result = Parser.parse("1 can black beans, drained", match_canonical: false)
      assert "drained" in result.preparations
    end
  end

  describe "parse/1 form detection" do
    test "detects canned form from unit" do
      result = Parser.parse("2 cans tomatoes", match_canonical: false)
      assert result.form == "canned"
    end

    test "detects canned form from text" do
      result = Parser.parse("1 cup canned tomatoes", match_canonical: false)
      assert result.form == "canned"
    end

    test "detects frozen form" do
      result = Parser.parse("2 cups frozen peas", match_canonical: false)
      assert result.form == "frozen"
    end

    test "detects dried form" do
      result = Parser.parse("1 lb dried pasta", match_canonical: false)
      assert result.form == "dried"
    end

    test "detects fresh form" do
      result = Parser.parse("1 bunch fresh parsley", match_canonical: false)
      assert result.form == "fresh"
    end

    test "detects jar form" do
      result = Parser.parse("1 jar marinara sauce", match_canonical: false)
      assert result.form == "jarred"
    end
  end

  describe "parse/1 cleaning ingredient names" do
    test "removes parentheticals" do
      result = Parser.parse("1 cup flour (about 120g)", match_canonical: false)
      assert result.raw_name == "flour"
    end

    test "removes optional notes" do
      result = Parser.parse("1 cup sugar (optional)", match_canonical: false)
      assert result.raw_name == "sugar"
    end

    test "trims whitespace" do
      result = Parser.parse("  2 cups  flour  ", match_canonical: false)
      assert result.raw_name == "flour"
    end

    # Regression: "of" should be stripped from ingredient names
    test "removes leading 'of' from ingredient name" do
      result = Parser.parse("1 cup of rice-bran oil", match_canonical: false)
      assert result.raw_name == "rice-bran oil"
    end

    test "removes 'of' after unit" do
      result = Parser.parse("2 tablespoons of olive oil", match_canonical: false)
      assert result.raw_name == "olive oil"
    end
  end

  describe "parse/1 fresh or dried alternatives" do
    # "fresh or dried" should create alternatives like "fresh X" and "dried X"
    test "handles 'fresh or dried' descriptor as alternatives" do
      result = Parser.parse("1 fresh or dried bay leaf", match_canonical: false)
      assert result.raw_name == "fresh bay leaf"
      assert "dried bay leaf" in result.alternatives
      refute String.contains?(result.raw_name, "or")
    end

    test "handles 'dried or fresh' descriptor as alternatives" do
      result = Parser.parse("2 dried or fresh thyme sprigs", match_canonical: false)
      assert result.raw_name == "dried thyme sprigs"
      assert "fresh thyme sprigs" in result.alternatives
    end

    test "extracts form from fresh or dried" do
      result = Parser.parse("1 fresh or dried bay leaf", match_canonical: false)
      # Form is detected from the primary (fresh bay leaf)
      assert result.form == "fresh"
    end
  end

  describe "parse/1 quantity ranges with 'or'" do
    # Regression: "2 or 3 tablespoons" should parse the range
    test "parses 'X or Y' quantity range" do
      result = Parser.parse("2 or 3 tablespoons fish sauce", match_canonical: false)
      # Should take average like numeric ranges, or take first value
      assert result.quantity in [2.0, 2.5, 3.0]
      assert result.unit == "tbsp"
      assert result.raw_name == "fish sauce"
    end

    test "parses 'X to Y' quantity range" do
      result = Parser.parse("3 to 4 cups chicken broth", match_canonical: false)
      assert result.quantity in [3.0, 3.5, 4.0]
      assert result.unit == "cup"
      assert result.raw_name == "chicken broth"
    end
  end

  describe "parse/1 with canonical matching" do
    setup do
      {:ok, _chicken} =
        Ingredients.create_canonical_ingredient(%{
          name: "chicken breast",
          display_name: "Chicken Breast",
          category: "protein",
          aliases: ["boneless skinless chicken breast"]
        })

      {:ok, _tomato} =
        Ingredients.create_canonical_ingredient(%{
          name: "tomato",
          display_name: "Tomato",
          category: "produce",
          aliases: ["tomatoes", "roma tomato"]
        })

      :ok
    end

    test "matches exact canonical name" do
      result = Parser.parse("1 lb chicken breast, diced")
      assert result.canonical_name == "chicken breast"
      assert result.canonical_id != nil
      assert result.confidence == 1.0
    end

    test "matches alias" do
      result = Parser.parse("2 boneless skinless chicken breast")
      assert result.canonical_name == "chicken breast"
      assert result.confidence == 1.0
    end

    test "matches partial name" do
      result = Parser.parse("1 large roma tomato")
      # Should match "tomato" after stripping "large" and "roma"
      assert result.canonical_name == "tomato"
    end

    test "returns nil for unknown ingredients" do
      result = Parser.parse("1 cup unicorn tears")
      assert result.canonical_name == nil
      assert result.canonical_id == nil
    end
  end

  describe "parse/1 complex examples" do
    test "parses full complex ingredient" do
      result = Parser.parse("2 (14.5 oz) cans diced tomatoes, drained", match_canonical: false)

      assert result.original == "2 (14.5 oz) cans diced tomatoes, drained"
      assert result.quantity == 2.0
      assert result.unit == "can"
      assert result.container == %{size_value: 14.5, size_unit: "oz"}
      assert "diced" in result.preparations
      assert "drained" in result.preparations
      assert result.form == "canned"
    end

    test "parses ingredient with modifiers" do
      result = Parser.parse("1/2 cup firmly packed brown sugar", match_canonical: false)
      assert result.quantity == 0.5
      assert result.unit == "cup"
      assert "firmly" in result.modifiers
      assert "packed" in result.modifiers
    end

    test "parses simple ingredient" do
      result = Parser.parse("salt and pepper to taste", match_canonical: false)
      assert result.quantity == nil
      assert result.unit == nil
      assert result.raw_name == "salt and pepper to taste"
    end
  end

  describe "parse/1 alternative measurements" do
    test "extracts metric weight in grams" do
      result = Parser.parse("1 cup (120g) flour", match_canonical: false)
      assert result.quantity == 1.0
      assert result.unit == "cup"
      assert result.alt_quantity == 120.0
      assert result.alt_unit == "g"
      assert result.raw_name == "flour"
    end

    test "extracts metric weight with space" do
      result = Parser.parse("2 cups (240 g) sugar", match_canonical: false)
      assert result.alt_quantity == 240.0
      assert result.alt_unit == "g"
    end

    test "extracts metric weight in grams spelled out" do
      result = Parser.parse("1 cup (120 grams) flour", match_canonical: false)
      assert result.alt_quantity == 120.0
      assert result.alt_unit == "g"
    end

    test "extracts metric volume in ml" do
      result = Parser.parse("2 tbsp olive oil (30 ml)", match_canonical: false)
      assert result.quantity == 2.0
      assert result.unit == "tbsp"
      assert result.alt_quantity == 30.0
      assert result.alt_unit == "ml"
    end

    test "extracts 'about X cups' pattern" do
      result = Parser.parse("12 oz cheese (about 4 cups)", match_canonical: false)
      assert result.quantity == 12.0
      assert result.unit == "oz"
      assert result.alt_quantity == 4.0
      assert result.alt_unit == "cup"
    end

    test "extracts 'approximately X cups' pattern" do
      result = Parser.parse("8 oz butter (approximately 2 sticks)", match_canonical: false)
      assert result.alt_quantity == 2.0
      assert result.alt_unit == "stick"
    end

    test "does not extract percentage as measurement" do
      result = Parser.parse("7 oz chocolate (70% cacao)", match_canonical: false)
      assert result.quantity == 7.0
      assert result.alt_quantity == nil
      assert result.alt_unit == nil
    end

    test "does not extract container size as alt measurement" do
      result = Parser.parse("2 (14.5 oz) cans tomatoes", match_canonical: false)
      assert result.quantity == 2.0
      assert result.unit == "can"
      assert result.container == %{size_value: 14.5, size_unit: "oz"}
      # Container size should NOT be in alt_quantity
      assert result.alt_quantity == nil
    end

    test "handles metric at end of ingredient" do
      result = Parser.parse("3 1/2 cups all-purpose flour (420g)", match_canonical: false)
      assert result.quantity == 3.5
      assert result.unit == "cup"
      assert result.alt_quantity == 420.0
      assert result.alt_unit == "g"
    end
  end

  describe "parse_ingredient_map/2" do
    test "parses from map with string key" do
      result = Parser.parse_ingredient_map(%{"text" => "2 cups flour"}, match_canonical: false)
      assert result.quantity == 2.0
      assert result.unit == "cup"
      assert result.raw_name == "flour"
    end

    test "parses from map with atom key" do
      result = Parser.parse_ingredient_map(%{text: "2 cups flour"}, match_canonical: false)
      assert result.quantity == 2.0
    end

    test "handles invalid input" do
      result = Parser.parse_ingredient_map(%{}, [])
      assert result.quantity == nil
      assert result.raw_name == ""
    end
  end

  describe "to_jsonb_map/1" do
    test "converts parsed ingredient to JSONB-compatible map" do
      parsed = %ParsedIngredient{
        original: "2 (14.5 oz) cans diced tomatoes",
        canonical_name: "tomato",
        canonical_id: "some-uuid",
        form: "canned",
        quantity: 2.0,
        unit: "can",
        container: %{size_value: 14.5, size_unit: "oz"},
        preparations: ["diced"],
        modifiers: [],
        confidence: 0.95,
        raw_name: "tomatoes"
      }

      result = Parser.to_jsonb_map(parsed)

      assert result["canonical_name"] == "tomato"
      assert result["canonical_id"] == "some-uuid"
      assert result["form"] == "canned"
      assert result["quantity"]["value"] == 2.0
      assert result["quantity"]["unit"] == "can"
      assert result["container_size"]["size_value"] == 14.5
      assert result["preparations"] == ["diced"]
      assert result["confidence"] == 0.95
    end

    test "omits container_size when nil" do
      parsed = %ParsedIngredient{
        original: "2 cups flour",
        canonical_name: "flour",
        canonical_id: nil,
        form: nil,
        quantity: 2.0,
        unit: "cup",
        container: nil,
        preparations: [],
        modifiers: [],
        confidence: 0.5,
        raw_name: "flour"
      }

      result = Parser.to_jsonb_map(parsed)
      refute Map.has_key?(result, "container_size")
    end
  end
end
