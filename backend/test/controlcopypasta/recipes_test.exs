defmodule Controlcopypasta.RecipesTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Recipes.{Recipe, Tag}

  import Controlcopypasta.AccountsFixtures
  import Controlcopypasta.RecipesFixtures

  describe "recipes" do
    test "list_recipes/0 returns all recipes" do
      recipe = recipe_fixture()
      recipes = Recipes.list_recipes()
      assert length(recipes) == 1
      assert hd(recipes).id == recipe.id
    end

    test "list_recipes_for_user/2 returns only user's recipes" do
      user1 = user_fixture()
      user2 = user_fixture()
      recipe1 = recipe_fixture(%{user: user1})
      _recipe2 = recipe_fixture(%{user: user2})

      recipes = Recipes.list_recipes_for_user(user1.id)
      assert length(recipes) == 1
      assert hd(recipes).id == recipe1.id
    end

    test "list_recipes/1 filters by tag" do
      user = user_fixture()
      tag = tag_fixture(%{name: "dinner"})
      recipe_with_tag = recipe_fixture(%{user: user, tag_ids: [tag.id]})
      _recipe_without_tag = recipe_fixture(%{user: user})

      recipes = Recipes.list_recipes(%{"tag" => "dinner"})
      assert length(recipes) == 1
      assert hd(recipes).id == recipe_with_tag.id
    end

    test "list_recipes/1 searches by title" do
      user = user_fixture()
      recipe1 = recipe_fixture(%{user: user, title: "Chocolate Cake"})
      _recipe2 = recipe_fixture(%{user: user, title: "Beef Stew"})

      recipes = Recipes.list_recipes(%{"q" => "chocolate"})
      assert length(recipes) == 1
      assert hd(recipes).id == recipe1.id
    end

    test "list_recipes/1 searches by description" do
      user = user_fixture()
      recipe1 = recipe_fixture(%{user: user, description: "A creamy pasta dish"})
      _recipe2 = recipe_fixture(%{user: user, description: "Grilled meat"})

      recipes = Recipes.list_recipes(%{"q" => "pasta"})
      assert length(recipes) == 1
      assert hd(recipes).id == recipe1.id
    end

    test "list_recipes/1 applies pagination" do
      user = user_fixture()
      for _ <- 1..5, do: recipe_fixture(%{user: user})

      recipes = Recipes.list_recipes(%{"limit" => "2", "offset" => "0"})
      assert length(recipes) == 2

      recipes = Recipes.list_recipes(%{"limit" => "2", "offset" => "3"})
      assert length(recipes) == 2
    end

    test "get_recipe/1 returns the recipe with given id" do
      recipe = recipe_fixture()
      fetched = Recipes.get_recipe(recipe.id)
      assert fetched.id == recipe.id
      assert fetched.title == recipe.title
    end

    test "get_recipe/1 returns nil for non-existent id" do
      assert Recipes.get_recipe(Ecto.UUID.generate()) == nil
    end

    test "get_recipe!/1 returns the recipe with given id" do
      recipe = recipe_fixture()
      fetched = Recipes.get_recipe!(recipe.id)
      assert fetched.id == recipe.id
    end

    test "get_recipe!/1 raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Recipes.get_recipe!(Ecto.UUID.generate())
      end
    end

    test "get_recipe_for_user/2 returns recipe only if owned by user" do
      user = user_fixture()
      other_user = user_fixture()
      recipe = recipe_fixture(%{user: user})

      assert Recipes.get_recipe_for_user(user.id, recipe.id).id == recipe.id
      assert Recipes.get_recipe_for_user(other_user.id, recipe.id) == nil
    end

    test "create_recipe/1 with valid data creates a recipe" do
      user = user_fixture()
      attrs = valid_recipe_attributes(%{user_id: user.id})

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)
      assert recipe.title == attrs.title
      assert recipe.description == attrs.description
      assert recipe.ingredients == attrs.ingredients
      assert recipe.instructions == attrs.instructions
    end

    test "create_recipe/1 extracts domain from source_url" do
      user = user_fixture()

      attrs =
        valid_recipe_attributes(%{
          user_id: user.id,
          source_url: "https://www.example.com/recipe/123"
        })

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)
      assert recipe.source_domain == "example.com"
    end

    test "create_recipe/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Recipes.create_recipe(%{})
    end

    test "create_recipe/1 with tag_ids associates tags" do
      user = user_fixture()
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      attrs = valid_recipe_attributes(%{user_id: user.id, tag_ids: [tag1.id, tag2.id]})

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)
      assert length(recipe.tags) == 2
      tag_ids = Enum.map(recipe.tags, & &1.id)
      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
    end

    test "update_recipe/2 with valid data updates the recipe" do
      recipe = recipe_fixture()
      update_attrs = %{title: "Updated Title", description: "Updated description"}

      assert {:ok, %Recipe{} = updated} = Recipes.update_recipe(recipe, update_attrs)
      assert updated.title == "Updated Title"
      assert updated.description == "Updated description"
    end

    test "update_recipe/2 can update tags" do
      recipe = recipe_fixture()
      tag = tag_fixture()

      assert {:ok, %Recipe{} = updated} = Recipes.update_recipe(recipe, %{tag_ids: [tag.id]})
      assert length(updated.tags) == 1
      assert hd(updated.tags).id == tag.id
    end

    test "update_recipe/2 with invalid data returns error changeset" do
      recipe = recipe_fixture()
      assert {:error, %Ecto.Changeset{}} = Recipes.update_recipe(recipe, %{title: nil})
    end

    test "delete_recipe/1 deletes the recipe" do
      recipe = recipe_fixture()
      assert {:ok, %Recipe{}} = Recipes.delete_recipe(recipe)
      assert Recipes.get_recipe(recipe.id) == nil
    end
  end

  describe "tags" do
    test "list_tags/0 returns all tags ordered by name" do
      tag2 = tag_fixture(%{name: "zebra"})
      tag1 = tag_fixture(%{name: "apple"})

      tags = Recipes.list_tags()
      assert length(tags) == 2
      assert hd(tags).id == tag1.id
      assert List.last(tags).id == tag2.id
    end

    test "get_tag/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Recipes.get_tag(tag.id).id == tag.id
    end

    test "get_tag/1 returns nil for non-existent id" do
      assert Recipes.get_tag(Ecto.UUID.generate()) == nil
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Recipes.get_tag!(tag.id).id == tag.id
    end

    test "get_tag!/1 raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Recipes.get_tag!(Ecto.UUID.generate())
      end
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Recipes.create_tag(%{name: "breakfast"})
      assert tag.name == "breakfast"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Recipes.create_tag(%{name: nil})
    end

    test "create_tag/1 enforces unique names" do
      tag_fixture(%{name: "unique"})
      assert {:error, changeset} = Recipes.create_tag(%{name: "unique"})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "create_tag/1 validates name length" do
      long_name = String.duplicate("a", 101)
      assert {:error, changeset} = Recipes.create_tag(%{name: long_name})
      assert "should be at most 100 character(s)" in errors_on(changeset).name
    end

    test "get_or_create_tag/1 returns existing tag if name exists" do
      existing = tag_fixture(%{name: "existing"})
      assert {:ok, tag} = Recipes.get_or_create_tag("existing")
      assert tag.id == existing.id
    end

    test "get_or_create_tag/1 creates new tag if name doesn't exist" do
      assert {:ok, tag} = Recipes.get_or_create_tag("newname")
      assert tag.name == "newname"
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Recipes.delete_tag(tag)
      assert Recipes.get_tag(tag.id) == nil
    end
  end
end
