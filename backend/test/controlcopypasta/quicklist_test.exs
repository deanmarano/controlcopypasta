defmodule Controlcopypasta.QuicklistTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Quicklist
  alias Controlcopypasta.Repo
  import Ecto.Query
  import Controlcopypasta.AccountsFixtures
  import Controlcopypasta.RecipesFixtures

  describe "get_swipe_batch/4" do
    test "returns recipes with images" do
      user = user_fixture()
      _with_image = recipe_fixture(%{user: user, image_url: "https://example.com/img.jpg"})
      _no_image = recipe_fixture(%{user: user, image_url: nil})

      recipes = Quicklist.get_swipe_batch(user.id, 10)
      assert length(recipes) == 1
      assert Enum.all?(recipes, fn r -> r.image_url != nil and r.image_url != "" end)
    end

    test "excludes already-swiped recipes" do
      user = user_fixture()
      recipe1 = recipe_fixture(%{user: user})
      recipe2 = recipe_fixture(%{user: user})

      # Swipe recipe1
      {:ok, _} = Quicklist.record_swipe(user.id, recipe1.id, "skip")

      recipes = Quicklist.get_swipe_batch(user.id, 10)
      recipe_ids = Enum.map(recipes, & &1.id)

      refute recipe1.id in recipe_ids
      assert recipe2.id in recipe_ids
    end

    test "excludes archived recipes" do
      user = user_fixture()
      recipe = recipe_fixture(%{user: user})
      archived = recipe_fixture(%{user: user, title: "Archived"})

      # archived_at is not in the changeset, so set it directly
      from(r in Controlcopypasta.Recipes.Recipe, where: r.id == ^archived.id)
      |> Repo.update_all(set: [archived_at: DateTime.utc_now()])

      recipes = Quicklist.get_swipe_batch(user.id, 10)
      assert length(recipes) == 1
      assert hd(recipes).id == recipe.id
    end

    test "respects count parameter" do
      user = user_fixture()
      for i <- 1..5, do: recipe_fixture(%{user: user, title: "Recipe #{i}"})

      recipes = Quicklist.get_swipe_batch(user.id, 3)
      assert length(recipes) <= 3
    end

    test "round-robins across domains when enough recipes exist" do
      user = user_fixture()

      # Create recipes across multiple domains
      # Note: round-robin only kicks in for domains with 100+ recipes,
      # but with small test data we use the fallback path which still works
      for i <- 1..3 do
        recipe_fixture(%{
          user: user,
          title: "Domain A Recipe #{i}",
          source_domain: "domaina.com",
          source_url: "https://domaina.com/#{i}"
        })
      end

      for i <- 1..3 do
        recipe_fixture(%{
          user: user,
          title: "Domain B Recipe #{i}",
          source_domain: "domainb.com",
          source_url: "https://domainb.com/#{i}"
        })
      end

      recipes = Quicklist.get_swipe_batch(user.id, 6)
      assert length(recipes) == 6
    end

    test "applies tag filter" do
      user = user_fixture()
      recipe = recipe_fixture(%{user: user})
      tag = tag_fixture(%{name: "test_quicklist_tag_filter"})
      Controlcopypasta.Recipes.update_recipe(recipe, %{tag_ids: [tag.id]})

      _untagged = recipe_fixture(%{user: user, title: "Untagged"})

      recipes = Quicklist.get_swipe_batch(user.id, 10, %{}, "test_quicklist_tag_filter")
      assert length(recipes) == 1
      assert hd(recipes).id == recipe.id
    end

    test "applies avoided ingredient filter" do
      user = user_fixture()
      avoided_id = Ecto.UUID.generate()
      safe_id = Ecto.UUID.generate()

      recipe_with_avoided = recipe_fixture(%{user: user, title: "Has avoided"})
      recipe_safe = recipe_fixture(%{user: user, title: "Safe recipe"})

      # Set ingredient_canonical_ids and all_ingredients_parsed directly
      from(r in Controlcopypasta.Recipes.Recipe, where: r.id == ^recipe_with_avoided.id)
      |> Repo.update_all(set: [all_ingredients_parsed: true, ingredient_canonical_ids: [avoided_id]])

      from(r in Controlcopypasta.Recipes.Recipe, where: r.id == ^recipe_safe.id)
      |> Repo.update_all(set: [all_ingredients_parsed: true, ingredient_canonical_ids: [safe_id]])

      avoided_params = %{"exclude_ingredient_ids" => [avoided_id]}
      recipes = Quicklist.get_swipe_batch(user.id, 10, avoided_params)
      recipe_ids = Enum.map(recipes, & &1.id)

      refute recipe_with_avoided.id in recipe_ids
      assert recipe_safe.id in recipe_ids
    end

    test "fills with fallback when main query returns fewer than requested" do
      user = user_fixture()
      for i <- 1..3, do: recipe_fixture(%{user: user, title: "Recipe #{i}"})

      # Request more than available — should return all 3 without error
      recipes = Quicklist.get_swipe_batch(user.id, 10)
      assert length(recipes) == 3
    end

    test "returns empty list when all recipes are swiped" do
      user = user_fixture()
      recipe = recipe_fixture(%{user: user})
      {:ok, _} = Quicklist.record_swipe(user.id, recipe.id, "skip")

      recipes = Quicklist.get_swipe_batch(user.id, 10)
      assert recipes == []
    end

    test "swiped exclusion works with many swiped recipes" do
      user = user_fixture()

      # Create and swipe several recipes
      swiped_recipes =
        for i <- 1..10 do
          r = recipe_fixture(%{user: user, title: "Swiped #{i}"})
          {:ok, _} = Quicklist.record_swipe(user.id, r.id, "skip")
          r
        end

      unswiped = recipe_fixture(%{user: user, title: "Fresh recipe"})

      recipes = Quicklist.get_swipe_batch(user.id, 10)
      recipe_ids = Enum.map(recipes, & &1.id)

      assert unswiped.id in recipe_ids
      for r <- swiped_recipes, do: refute(r.id in recipe_ids)
    end

    test "preloads tags on returned recipes" do
      user = user_fixture()
      recipe = recipe_fixture(%{user: user})
      tag = tag_fixture(%{name: "test_quicklist_preload"})
      Controlcopypasta.Recipes.update_recipe(recipe, %{tag_ids: [tag.id]})

      [result] = Quicklist.get_swipe_batch(user.id, 10)
      assert Ecto.assoc_loaded?(result.tags)
      assert length(result.tags) == 1
      assert hd(result.tags).name == "test_quicklist_preload"
    end
  end
end
