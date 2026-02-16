defmodule ControlcopypastaWeb.RecipeControllerTest do
  use ControlcopypastaWeb.ConnCase, async: true

  import Controlcopypasta.AccountsFixtures
  import Controlcopypasta.RecipesFixtures

  setup :setup_authenticated_conn

  describe "GET /api/recipes (index)" do
    test "lists all recipes for authenticated user", %{conn: conn, user: user} do
      recipe = recipe_fixture(%{user: user})

      conn = get(conn, ~p"/api/recipes")
      response = json_response(conn, 200)

      assert length(response["data"]) == 1
      assert hd(response["data"])["id"] == recipe.id
    end

    test "does not list other users' recipes", %{conn: conn, user: _user} do
      other_user = user_fixture()
      _other_recipe = recipe_fixture(%{user: other_user})

      conn = get(conn, ~p"/api/recipes")
      response = json_response(conn, 200)

      assert response["data"] == []
    end

    test "filters by tag", %{conn: conn, user: user} do
      tag = tag_fixture(%{name: "dinner"})
      recipe_with_tag = recipe_fixture(%{user: user, tag_ids: [tag.id]})
      _recipe_without_tag = recipe_fixture(%{user: user})

      conn = get(conn, ~p"/api/recipes", %{tag: "dinner"})
      response = json_response(conn, 200)

      assert length(response["data"]) == 1
      assert hd(response["data"])["id"] == recipe_with_tag.id
    end

    test "searches by query", %{conn: conn, user: user} do
      recipe1 = recipe_fixture(%{user: user, title: "Chocolate Cake"})
      _recipe2 = recipe_fixture(%{user: user, title: "Beef Stew"})

      conn = get(conn, ~p"/api/recipes", %{q: "chocolate"})
      response = json_response(conn, 200)

      assert length(response["data"]) == 1
      assert hd(response["data"])["id"] == recipe1.id
    end

    test "returns 401 without authentication" do
      conn = build_conn() |> get(~p"/api/recipes")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/recipes/:id (show)" do
    test "returns recipe when owned by user", %{conn: conn, user: user} do
      recipe = recipe_fixture(%{user: user})

      conn = get(conn, ~p"/api/recipes/#{recipe.id}")
      response = json_response(conn, 200)

      assert response["data"]["id"] == recipe.id
      assert response["data"]["title"] == recipe.title
    end

    test "returns recipe owned by another user with is_owned false", %{conn: conn} do
      other_user = user_fixture()
      recipe = recipe_fixture(%{user: other_user})

      conn = get(conn, ~p"/api/recipes/#{recipe.id}")
      response = json_response(conn, 200)
      assert response["data"]["id"] == recipe.id
      assert response["data"]["is_owned"] == false
    end

    test "returns 404 for non-existent recipe", %{conn: conn} do
      conn = get(conn, ~p"/api/recipes/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end

  describe "POST /api/recipes (create)" do
    test "creates recipe with valid data", %{conn: conn, user: user} do
      attrs = %{
        recipe: %{
          title: "New Recipe",
          description: "A test recipe",
          ingredients: [%{text: "1 cup flour", group: nil}],
          instructions: [%{step: 1, text: "Mix it"}]
        }
      }

      conn = post(conn, ~p"/api/recipes", attrs)
      response = json_response(conn, 201)

      assert response["data"]["title"] == "New Recipe"
      assert response["data"]["description"] == "A test recipe"

      # Verify recipe belongs to authenticated user
      recipe = Controlcopypasta.Recipes.get_recipe!(response["data"]["id"])
      assert recipe.user_id == user.id
    end

    test "creates recipe with tags", %{conn: conn} do
      tag = tag_fixture()

      attrs = %{
        recipe: %{
          title: "Tagged Recipe",
          tag_ids: [tag.id]
        }
      }

      conn = post(conn, ~p"/api/recipes", attrs)
      response = json_response(conn, 201)

      assert length(response["data"]["tags"]) == 1
      assert hd(response["data"]["tags"])["id"] == tag.id
    end

    test "returns errors for invalid data", %{conn: conn} do
      attrs = %{recipe: %{title: nil}}

      conn = post(conn, ~p"/api/recipes", attrs)
      assert json_response(conn, 422)["errors"]
    end
  end

  describe "PUT /api/recipes/:id (update)" do
    test "updates recipe with valid data", %{conn: conn, user: user} do
      recipe = recipe_fixture(%{user: user})

      attrs = %{recipe: %{title: "Updated Title"}}

      conn = put(conn, ~p"/api/recipes/#{recipe.id}", attrs)
      response = json_response(conn, 200)

      assert response["data"]["title"] == "Updated Title"
    end

    test "updates recipe tags", %{conn: conn, user: user} do
      recipe = recipe_fixture(%{user: user})
      tag = tag_fixture()

      attrs = %{recipe: %{tag_ids: [tag.id]}}

      conn = put(conn, ~p"/api/recipes/#{recipe.id}", attrs)
      response = json_response(conn, 200)

      assert length(response["data"]["tags"]) == 1
    end

    test "returns 404 for recipe owned by another user", %{conn: conn} do
      other_user = user_fixture()
      recipe = recipe_fixture(%{user: other_user})

      attrs = %{recipe: %{title: "Hacked!"}}

      conn = put(conn, ~p"/api/recipes/#{recipe.id}", attrs)
      assert json_response(conn, 404)
    end

    test "returns errors for invalid data", %{conn: conn, user: user} do
      recipe = recipe_fixture(%{user: user})

      attrs = %{recipe: %{title: nil}}

      conn = put(conn, ~p"/api/recipes/#{recipe.id}", attrs)
      assert json_response(conn, 422)["errors"]
    end
  end

  describe "DELETE /api/recipes/:id" do
    test "deletes recipe when owned by user", %{conn: conn, user: user} do
      recipe = recipe_fixture(%{user: user})

      conn = delete(conn, ~p"/api/recipes/#{recipe.id}")
      assert response(conn, 204)

      assert Controlcopypasta.Recipes.get_recipe(recipe.id) == nil
    end

    test "returns 404 for recipe owned by another user", %{conn: conn} do
      other_user = user_fixture()
      recipe = recipe_fixture(%{user: other_user})

      conn = delete(conn, ~p"/api/recipes/#{recipe.id}")
      assert json_response(conn, 404)

      # Recipe should still exist
      assert Controlcopypasta.Recipes.get_recipe(recipe.id)
    end
  end

  describe "POST /api/recipes/parse" do
    test "returns error when URL is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/recipes/parse", %{})
      assert json_response(conn, 400)["error"]["message"] == "URL is required"
    end

    # Note: Testing actual URL parsing would require mocking HTTP requests
    # or using a test server. For now, we just test the error cases.
  end
end
