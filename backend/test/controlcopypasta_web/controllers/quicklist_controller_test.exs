defmodule ControlcopypastaWeb.QuicklistControllerTest do
  use ControlcopypastaWeb.ConnCase

  alias Controlcopypasta.RecipesFixtures
  alias Controlcopypasta.Recipes

  setup %{conn: conn} do
    setup_authenticated_conn(%{conn: conn})
  end

  describe "GET /api/quicklist/batch" do
    test "returns recipes", %{conn: conn, user: user} do
      _recipe = RecipesFixtures.recipe_fixture(%{user: user})

      conn = get(conn, "/api/quicklist/batch")
      assert %{"data" => recipes} = json_response(conn, 200)
      assert is_list(recipes)
    end

    test "filters by tag", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})
      tag = RecipesFixtures.tag_fixture(%{name: "dinner"})
      Recipes.update_recipe(recipe, %{tag_ids: [tag.id]})

      _other = RecipesFixtures.recipe_fixture(%{user: user, title: "No tag recipe"})

      conn = get(conn, "/api/quicklist/batch?tag=dinner")
      assert %{"data" => recipes} = json_response(conn, 200)
      assert length(recipes) == 1
      assert hd(recipes)["id"] == recipe.id
    end

    test "respects count param", %{conn: conn, user: user} do
      for _ <- 1..5, do: RecipesFixtures.recipe_fixture(%{user: user})

      conn = get(conn, "/api/quicklist/batch?count=2")
      assert %{"data" => recipes} = json_response(conn, 200)
      assert length(recipes) <= 2
    end
  end

  describe "POST /api/quicklist/swipe" do
    test "records a maybe swipe", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})

      conn = post(conn, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "maybe"})
      assert %{"data" => %{"action" => "maybe", "recipe_id" => recipe_id}} = json_response(conn, 201)
      assert recipe_id == recipe.id
    end

    test "records a skip swipe", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})

      conn = post(conn, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "skip"})
      assert %{"data" => %{"action" => "skip"}} = json_response(conn, 201)
    end

    test "upserts swipe action", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})

      # First swipe as skip
      conn1 = post(conn, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "skip"})
      assert json_response(conn1, 201)

      # Change to maybe - rebuild conn to avoid recycled state
      conn2 = recycle(conn) |> put_req_header("authorization", get_req_header(conn, "authorization") |> hd())
      conn2 = post(conn2, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "maybe"})
      assert %{"data" => %{"action" => "maybe"}} = json_response(conn2, 201)
    end

    test "excludes swiped recipes from batch", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})

      # Swipe the recipe
      conn1 = post(conn, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "skip"})
      assert json_response(conn1, 201)

      # Batch should not include it
      conn2 = recycle(conn) |> put_req_header("authorization", get_req_header(conn, "authorization") |> hd())
      conn2 = get(conn2, "/api/quicklist/batch")
      assert %{"data" => recipes} = json_response(conn2, 200)
      assert Enum.all?(recipes, fn r -> r["id"] != recipe.id end)
    end
  end

  describe "GET /api/quicklist/maybe" do
    test "lists maybe recipes", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})

      # Swipe as maybe
      conn1 = post(conn, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "maybe"})
      assert json_response(conn1, 201)

      # List maybes
      conn2 = recycle(conn) |> put_req_header("authorization", get_req_header(conn, "authorization") |> hd())
      conn2 = get(conn2, "/api/quicklist/maybe")
      assert %{"data" => recipes} = json_response(conn2, 200)
      assert length(recipes) == 1
      assert hd(recipes)["id"] == recipe.id
    end

    test "does not list skipped recipes", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})

      conn1 = post(conn, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "skip"})
      assert json_response(conn1, 201)

      conn2 = recycle(conn) |> put_req_header("authorization", get_req_header(conn, "authorization") |> hd())
      conn2 = get(conn2, "/api/quicklist/maybe")
      assert %{"data" => []} = json_response(conn2, 200)
    end
  end

  describe "DELETE /api/quicklist/maybe/:recipe_id" do
    test "removes recipe from maybe list", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})

      # Add to maybe
      conn1 = post(conn, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "maybe"})
      assert json_response(conn1, 201)

      # Remove
      conn2 = recycle(conn) |> put_req_header("authorization", get_req_header(conn, "authorization") |> hd())
      conn2 = delete(conn2, "/api/quicklist/maybe/#{recipe.id}")
      assert response(conn2, 204)

      # Verify removed
      conn3 = recycle(conn) |> put_req_header("authorization", get_req_header(conn, "authorization") |> hd())
      conn3 = get(conn3, "/api/quicklist/maybe")
      assert %{"data" => []} = json_response(conn3, 200)
    end

    test "removed recipe reappears in batch", %{conn: conn, user: user} do
      recipe = RecipesFixtures.recipe_fixture(%{user: user})

      # Swipe maybe
      conn1 = post(conn, "/api/quicklist/swipe", %{recipe_id: recipe.id, action: "maybe"})
      assert json_response(conn1, 201)

      # Remove from maybe (deletes swipe record)
      conn2 = recycle(conn) |> put_req_header("authorization", get_req_header(conn, "authorization") |> hd())
      conn2 = delete(conn2, "/api/quicklist/maybe/#{recipe.id}")
      assert response(conn2, 204)

      # Should appear in batch again
      conn3 = recycle(conn) |> put_req_header("authorization", get_req_header(conn, "authorization") |> hd())
      conn3 = get(conn3, "/api/quicklist/batch")
      assert %{"data" => recipes} = json_response(conn3, 200)
      assert Enum.any?(recipes, fn r -> r["id"] == recipe.id end)
    end
  end
end
