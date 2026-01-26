defmodule Controlcopypasta.SimilarityTest do
  use Controlcopypasta.DataCase

  alias Controlcopypasta.Similarity
  alias Controlcopypasta.Similarity.{IngredientParser, IngredientNormalizer}

  describe "IngredientParser.parse/1" do
    test "parses simple quantity and ingredient" do
      result = IngredientParser.parse("2 cups flour")
      assert result.quantity == 2.0
      assert result.unit == "cup"
      assert result.name == "flour"
    end

    test "parses fraction quantity" do
      result = IngredientParser.parse("1/2 cup sugar")
      assert result.quantity == 0.5
      assert result.unit == "cup"
      assert result.name == "sugar"
    end

    test "parses mixed number" do
      result = IngredientParser.parse("1 1/2 tsp vanilla extract")
      assert result.quantity == 1.5
      assert result.unit == "tsp"
      assert result.name == "vanilla extract"
    end

    test "parses ingredient without unit" do
      result = IngredientParser.parse("3 large eggs")
      assert result.quantity == 3.0
      assert result.unit == nil
      assert result.name == "eggs"
    end

    test "parses ingredient without quantity" do
      result = IngredientParser.parse("salt to taste")
      assert result.quantity == nil
      assert result.unit == nil
      assert result.name == "salt to taste"
    end

    test "normalizes tablespoon variations" do
      assert IngredientParser.parse("2 tablespoons butter").unit == "tbsp"
      assert IngredientParser.parse("2 tbsp butter").unit == "tbsp"
      assert IngredientParser.parse("2 tbs butter").unit == "tbsp"
    end

    test "handles unicode fractions" do
      result = IngredientParser.parse("½ cup milk")
      assert result.quantity == 0.5
      assert result.unit == "cup"
    end

    test "handles ranges by averaging" do
      result = IngredientParser.parse("2-3 cups water")
      assert result.quantity == 2.5
    end
  end

  describe "IngredientNormalizer.normalize/1" do
    test "normalizes common ingredient variations" do
      assert IngredientNormalizer.normalize("all-purpose flour") == "flour"
      assert IngredientNormalizer.normalize("unsalted butter") == "butter"
      assert IngredientNormalizer.normalize("extra virgin olive oil") == "olive oil"
    end

    test "normalizes plurals" do
      assert IngredientNormalizer.normalize("eggs") == "egg"
      assert IngredientNormalizer.normalize("tomatoes") == "tomato"
    end

    test "normalizes salt variations" do
      assert IngredientNormalizer.normalize("kosher salt") == "salt"
      assert IngredientNormalizer.normalize("sea salt") == "salt"
    end

    test "strips descriptors" do
      assert IngredientNormalizer.normalize("large eggs") == "egg"
      assert IngredientNormalizer.normalize("fresh parsley") == "parsley"
    end
  end

  describe "Similarity.build_ingredient_vector/1" do
    test "builds vector from recipe ingredients" do
      recipe = %Controlcopypasta.Recipes.Recipe{
        id: Ecto.UUID.generate(),
        title: "Test Recipe",
        ingredients: [
          %{"text" => "2 cups flour"},
          %{"text" => "1 cup sugar"},
          %{"text" => "1/2 cup butter"}
        ]
      }

      vector = Similarity.build_ingredient_vector(recipe)

      assert map_size(vector) == 3
      assert Map.has_key?(vector, "flour")
      assert Map.has_key?(vector, "sugar")
      assert Map.has_key?(vector, "butter")

      # Proportions should sum to ~1.0
      total = Enum.sum(Map.values(vector))
      assert_in_delta total, 1.0, 0.01
    end

    test "aggregates duplicate ingredients" do
      recipe = %Controlcopypasta.Recipes.Recipe{
        id: Ecto.UUID.generate(),
        title: "Test Recipe",
        ingredients: [
          %{"text" => "1 cup all-purpose flour"},
          %{"text" => "1/2 cup bread flour"}
        ]
      }

      vector = Similarity.build_ingredient_vector(recipe)

      # Both should normalize to "flour" and "bread flour" respectively
      assert Map.has_key?(vector, "flour")
    end
  end

  describe "Similarity.jaccard_similarity/2" do
    test "returns 1.0 for identical sets" do
      set1 = MapSet.new(["flour", "sugar", "butter"])
      set2 = MapSet.new(["flour", "sugar", "butter"])

      assert Similarity.jaccard_similarity(set1, set2) == 1.0
    end

    test "returns 0.0 for disjoint sets" do
      set1 = MapSet.new(["flour", "sugar"])
      set2 = MapSet.new(["chicken", "salt"])

      assert Similarity.jaccard_similarity(set1, set2) == 0.0
    end

    test "returns partial similarity for overlapping sets" do
      set1 = MapSet.new(["flour", "sugar", "butter"])
      set2 = MapSet.new(["flour", "sugar", "eggs"])

      # Intersection: 2 (flour, sugar), Union: 4 (flour, sugar, butter, eggs)
      assert_in_delta Similarity.jaccard_similarity(set1, set2), 0.5, 0.01
    end
  end

  describe "Similarity.cosine_similarity/2" do
    test "returns 1.0 for identical vectors" do
      vec1 = %{"flour" => 0.5, "sugar" => 0.3, "butter" => 0.2}
      vec2 = %{"flour" => 0.5, "sugar" => 0.3, "butter" => 0.2}

      assert_in_delta Similarity.cosine_similarity(vec1, vec2), 1.0, 0.01
    end

    test "returns 0.0 for orthogonal vectors" do
      vec1 = %{"flour" => 1.0}
      vec2 = %{"sugar" => 1.0}

      assert Similarity.cosine_similarity(vec1, vec2) == 0.0
    end

    test "returns partial similarity for similar vectors" do
      vec1 = %{"flour" => 0.5, "sugar" => 0.5}
      vec2 = %{"flour" => 0.8, "sugar" => 0.2}

      # Both have same ingredients but different proportions
      similarity = Similarity.cosine_similarity(vec1, vec2)
      assert similarity > 0.5
      assert similarity < 1.0
    end
  end

  describe "Similarity.compare/2" do
    test "compares two recipes" do
      recipe1 = %Controlcopypasta.Recipes.Recipe{
        id: Ecto.UUID.generate(),
        title: "Cake",
        ingredients: [
          %{"text" => "2 cups flour"},
          %{"text" => "1 cup sugar"},
          %{"text" => "1/2 cup butter"}
        ]
      }

      recipe2 = %Controlcopypasta.Recipes.Recipe{
        id: Ecto.UUID.generate(),
        title: "Cookies",
        ingredients: [
          %{"text" => "2 cups flour"},
          %{"text" => "1/2 cup sugar"},
          %{"text" => "1 cup butter"},
          %{"text" => "2 eggs"}
        ]
      }

      comparison = Similarity.compare(recipe1, recipe2)

      assert comparison.score > 0
      assert comparison.overlap_score > 0
      assert comparison.proportion_score > 0
      assert length(comparison.shared_ingredients) == 3
      assert length(comparison.only_in_first) == 0
      assert length(comparison.only_in_second) == 1
    end
  end
end
