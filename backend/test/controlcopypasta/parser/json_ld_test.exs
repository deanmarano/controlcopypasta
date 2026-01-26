defmodule Controlcopypasta.Parser.JsonLdTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Parser.JsonLd

  @simple_recipe_html """
  <html>
  <head>
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "Recipe",
      "name": "Chocolate Chip Cookies",
      "description": "Delicious homemade cookies",
      "image": "https://example.com/cookie.jpg",
      "recipeIngredient": [
        "2 cups flour",
        "1 cup sugar",
        "1 cup chocolate chips"
      ],
      "recipeInstructions": [
        {"@type": "HowToStep", "text": "Mix dry ingredients"},
        {"@type": "HowToStep", "text": "Add wet ingredients"},
        {"@type": "HowToStep", "text": "Bake at 350F for 12 minutes"}
      ],
      "prepTime": "PT15M",
      "cookTime": "PT12M",
      "totalTime": "PT27M",
      "recipeYield": "24 cookies"
    }
    </script>
  </head>
  <body></body>
  </html>
  """

  @graph_recipe_html """
  <html>
  <head>
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@graph": [
        {"@type": "WebPage", "name": "Recipe Page"},
        {
          "@type": "Recipe",
          "name": "Pasta Carbonara",
          "description": "Classic Italian pasta",
          "recipeIngredient": ["400g pasta", "200g guanciale"],
          "recipeInstructions": ["Cook pasta", "Add sauce"]
        }
      ]
    }
    </script>
  </head>
  <body></body>
  </html>
  """

  @array_recipe_html """
  <html>
  <head>
    <script type="application/ld+json">
    [
      {"@type": "WebPage", "name": "Page"},
      {
        "@type": "Recipe",
        "name": "Simple Salad",
        "recipeIngredient": ["lettuce", "tomato"]
      }
    ]
    </script>
  </head>
  <body></body>
  </html>
  """

  @multi_type_recipe_html """
  <html>
  <head>
    <script type="application/ld+json">
    {
      "@type": ["Recipe", "HowTo"],
      "name": "Multi-type Recipe",
      "recipeIngredient": ["ingredient 1"]
    }
    </script>
  </head>
  <body></body>
  </html>
  """

  describe "extract/1" do
    test "extracts recipe from simple JSON-LD" do
      assert {:ok, recipe} = JsonLd.extract(@simple_recipe_html)
      assert recipe.title == "Chocolate Chip Cookies"
      assert recipe.description == "Delicious homemade cookies"
      assert recipe.image_url == "https://example.com/cookie.jpg"
    end

    test "extracts ingredients" do
      assert {:ok, recipe} = JsonLd.extract(@simple_recipe_html)
      assert length(recipe.ingredients) == 3
      assert hd(recipe.ingredients)["text"] == "2 cups flour"
    end

    test "extracts instructions" do
      assert {:ok, recipe} = JsonLd.extract(@simple_recipe_html)
      assert length(recipe.instructions) == 3
      assert hd(recipe.instructions)["text"] == "Mix dry ingredients"
      assert hd(recipe.instructions)["step"] == 1
    end

    test "parses prep time from ISO 8601 duration" do
      assert {:ok, recipe} = JsonLd.extract(@simple_recipe_html)
      assert recipe.prep_time_minutes == 15
    end

    test "parses cook time from ISO 8601 duration" do
      assert {:ok, recipe} = JsonLd.extract(@simple_recipe_html)
      assert recipe.cook_time_minutes == 12
    end

    test "parses total time from ISO 8601 duration" do
      assert {:ok, recipe} = JsonLd.extract(@simple_recipe_html)
      assert recipe.total_time_minutes == 27
    end

    test "extracts servings/yield" do
      assert {:ok, recipe} = JsonLd.extract(@simple_recipe_html)
      assert recipe.servings == "24 cookies"
    end

    test "extracts recipe from @graph structure" do
      assert {:ok, recipe} = JsonLd.extract(@graph_recipe_html)
      assert recipe.title == "Pasta Carbonara"
      assert recipe.description == "Classic Italian pasta"
    end

    test "extracts recipe from array structure" do
      assert {:ok, recipe} = JsonLd.extract(@array_recipe_html)
      assert recipe.title == "Simple Salad"
    end

    test "handles multi-type recipes" do
      assert {:ok, recipe} = JsonLd.extract(@multi_type_recipe_html)
      assert recipe.title == "Multi-type Recipe"
    end

    test "returns error for HTML without JSON-LD" do
      html = "<html><body>No recipe here</body></html>"
      assert {:error, :no_json_ld} = JsonLd.extract(html)
    end

    test "returns error for JSON-LD without recipe" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">{"@type": "WebPage", "name": "Not a recipe"}</script>
      </head>
      <body></body>
      </html>
      """

      # Returns :no_json_ld because after checking all JSON-LD scripts, no recipe was found
      assert {:error, :no_json_ld} = JsonLd.extract(html)
    end
  end

  describe "duration parsing" do
    test "parses hours only" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "prepTime": "PT2H"}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.prep_time_minutes == 120
    end

    test "parses hours and minutes" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "prepTime": "PT1H30M"}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.prep_time_minutes == 90
    end

    test "handles missing time fields" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test"}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.prep_time_minutes == nil
      assert recipe.cook_time_minutes == nil
      assert recipe.total_time_minutes == nil
    end
  end

  describe "image extraction" do
    test "extracts image from string" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "image": "https://example.com/img.jpg"}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.image_url == "https://example.com/img.jpg"
    end

    test "extracts image from object with url" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "image": {"url": "https://example.com/img.jpg"}}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.image_url == "https://example.com/img.jpg"
    end

    test "extracts first image from array of strings" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "image": ["https://example.com/1.jpg", "https://example.com/2.jpg"]}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.image_url == "https://example.com/1.jpg"
    end

    test "extracts first image from array of objects" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "image": [{"url": "https://example.com/1.jpg"}]}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.image_url == "https://example.com/1.jpg"
    end
  end

  describe "servings extraction" do
    test "extracts string yield" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "recipeYield": "4 servings"}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.servings == "4 servings"
    end

    test "extracts first yield from array" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "recipeYield": ["8 pieces", "4 servings"]}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.servings == "8 pieces"
    end

    test "converts integer yield to string" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "recipeYield": 4}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert recipe.servings == "4"
    end
  end

  describe "instruction parsing" do
    test "handles string instructions" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "recipeInstructions": ["Step 1", "Step 2"]}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert length(recipe.instructions) == 2
      assert hd(recipe.instructions)["text"] == "Step 1"
    end

    test "strips HTML from instruction text" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Test", "recipeInstructions": [{"@type": "HowToStep", "text": "<p>Mix <strong>well</strong></p>"}]}
        </script>
      </head>
      </html>
      """

      assert {:ok, recipe} = JsonLd.extract(html)
      assert hd(recipe.instructions)["text"] == "Mix well"
    end
  end
end
