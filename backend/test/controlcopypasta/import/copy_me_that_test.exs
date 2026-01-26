defmodule Controlcopypasta.Import.CopyMeThatTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Import.CopyMeThat
  alias Controlcopypasta.Recipes

  import Controlcopypasta.AccountsFixtures

  describe "import_json/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "imports recipes from JSON array", %{user: user} do
      recipes = [
        %{
          "name" => "Test Recipe",
          "description" => "A test recipe",
          "url" => "https://example.com/recipe",
          "image" => "https://example.com/image.jpg",
          "ingredients" => ["1 cup flour", "2 eggs"],
          "instructions" => "Step 1. Mix ingredients.\nStep 2. Bake.",
          "notes" => "Great recipe!",
          "tags" => ["dinner", "easy"],
          "prepTime" => "15 mins",
          "cookTime" => "30 mins",
          "totalTime" => "45 mins",
          "yield" => "4 servings"
        }
      ]

      assert {:ok, result} = CopyMeThat.import_json(recipes, user.id)
      assert result.imported == 1
      assert result.failed == 0

      # Verify the recipe was created
      user_recipes = Recipes.list_recipes_for_user(user.id)
      assert length(user_recipes) == 1

      recipe = hd(user_recipes)
      assert recipe.title == "Test Recipe"
      assert recipe.description == "A test recipe"
      assert recipe.source_url == "https://example.com/recipe"
      assert recipe.image_url == "https://example.com/image.jpg"
      assert recipe.prep_time_minutes == 15
      assert recipe.cook_time_minutes == 30
      assert recipe.total_time_minutes == 45
      assert recipe.servings == "4 servings"
      assert recipe.notes == "Great recipe!"
    end

    test "normalizes ingredients from string list", %{user: user} do
      recipes = [
        %{
          "name" => "Test",
          "ingredients" => ["1 cup flour", "2 eggs", "1/2 tsp salt"]
        }
      ]

      {:ok, _} = CopyMeThat.import_json(recipes, user.id)
      recipe = hd(Recipes.list_recipes_for_user(user.id))

      assert length(recipe.ingredients) == 3
      assert hd(recipe.ingredients)["text"] == "1 cup flour"
      assert hd(recipe.ingredients)["group"] == nil
    end

    test "normalizes ingredients from newline-separated string", %{user: user} do
      recipes = [
        %{
          "name" => "Test",
          "ingredients" => "1 cup flour\n2 eggs\n1/2 tsp salt"
        }
      ]

      {:ok, _} = CopyMeThat.import_json(recipes, user.id)
      recipe = hd(Recipes.list_recipes_for_user(user.id))

      assert length(recipe.ingredients) == 3
    end

    test "normalizes instructions and removes step prefixes", %{user: user} do
      recipes = [
        %{
          "name" => "Test",
          "instructions" => "Step 1. Mix ingredients.\n2. Add eggs.\nStep 3) Bake."
        }
      ]

      {:ok, _} = CopyMeThat.import_json(recipes, user.id)
      recipe = hd(Recipes.list_recipes_for_user(user.id))

      assert length(recipe.instructions) == 3
      assert Enum.at(recipe.instructions, 0)["step"] == 1
      assert Enum.at(recipe.instructions, 0)["text"] == "Mix ingredients."
      assert Enum.at(recipe.instructions, 1)["text"] == "Add eggs."
      assert Enum.at(recipe.instructions, 2)["text"] == "Bake."
    end

    test "creates and associates tags", %{user: user} do
      recipes = [
        %{
          "name" => "Test",
          "tags" => ["dinner", "quick", "healthy"]
        }
      ]

      {:ok, _} = CopyMeThat.import_json(recipes, user.id)
      recipe = hd(Recipes.list_recipes_for_user(user.id))

      assert length(recipe.tags) == 3
      tag_names = Enum.map(recipe.tags, & &1.name)
      assert "dinner" in tag_names
      assert "quick" in tag_names
      assert "healthy" in tag_names
    end

    test "reuses existing tags", %{user: user} do
      # Create an existing tag
      {:ok, _existing_tag} = Recipes.create_tag(%{name: "dinner"})

      recipes = [
        %{"name" => "Test 1", "tags" => ["dinner"]},
        %{"name" => "Test 2", "tags" => ["dinner", "lunch"]}
      ]

      {:ok, _} = CopyMeThat.import_json(recipes, user.id)

      # Should only have 2 tags total (dinner reused)
      all_tags = Recipes.list_tags()
      assert length(all_tags) == 2
    end

    test "parses various time formats", %{user: user} do
      test_cases = [
        {"15 mins", 15},
        {"15 minutes", 15},
        {"15m", 15},
        {"1 hour", 60},
        {"1 hr", 60},
        {"1h", 60},
        {"1 hour 30 mins", 90},
        {"1h 30m", 90}
      ]

      for {time_string, expected_minutes} <- test_cases do
        recipes = [%{"name" => "Test", "prepTime" => time_string}]
        {:ok, _} = CopyMeThat.import_json(recipes, user.id)
        recipe = hd(Recipes.list_recipes_for_user(user.id))
        assert recipe.prep_time_minutes == expected_minutes, "Failed for #{time_string}"
        Recipes.delete_recipe(recipe)
      end
    end

    test "handles multiple recipes", %{user: user} do
      recipes = [
        %{"name" => "Recipe 1"},
        %{"name" => "Recipe 2"},
        %{"name" => "Recipe 3"}
      ]

      assert {:ok, result} = CopyMeThat.import_json(recipes, user.id)
      assert result.imported == 3
      assert result.failed == 0
    end

    test "imports from JSON string", %{user: user} do
      json = Jason.encode!([%{"name" => "JSON String Recipe"}])

      assert {:ok, result} = CopyMeThat.import_json(json, user.id)
      assert result.imported == 1
    end

    test "handles empty recipes array", %{user: user} do
      assert {:ok, result} = CopyMeThat.import_json([], user.id)
      assert result.imported == 0
      assert result.failed == 0
    end

    test "handles missing optional fields", %{user: user} do
      recipes = [%{"name" => "Minimal Recipe"}]

      {:ok, _} = CopyMeThat.import_json(recipes, user.id)
      recipe = hd(Recipes.list_recipes_for_user(user.id))

      assert recipe.title == "Minimal Recipe"
      assert recipe.description == nil
      assert recipe.ingredients == []
      assert recipe.instructions == []
    end
  end
end
