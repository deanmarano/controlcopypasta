defmodule ControlcopypastaWeb.ImportControllerTest do
  use ControlcopypastaWeb.ConnCase, async: true

  setup :setup_authenticated_conn

  describe "POST /api/import/copymethat" do
    test "imports recipes from JSON array", %{conn: conn, user: user} do
      recipes = [
        %{
          "name" => "Imported Recipe",
          "description" => "A test recipe",
          "ingredients" => ["flour", "eggs"],
          "instructions" => "Mix and bake",
          "tags" => ["test"]
        }
      ]

      conn = post(conn, ~p"/api/import/copymethat", %{recipes: recipes})
      response = json_response(conn, 200)

      assert response["imported"] == 1
      assert response["failed"] == 0
      assert response["message"] == "Import completed"

      # Verify recipe exists
      user_recipes = Controlcopypasta.Recipes.list_recipes_for_user(user.id)
      assert length(user_recipes) == 1
      assert hd(user_recipes).title == "Imported Recipe"
    end

    test "imports multiple recipes", %{conn: conn} do
      recipes = [
        %{"name" => "Recipe One"},
        %{"name" => "Recipe Two"}
      ]

      conn = post(conn, ~p"/api/import/copymethat", %{recipes: recipes})
      response = json_response(conn, 200)

      assert response["imported"] == 2
      assert response["failed"] == 0
    end

    test "handles empty recipes array", %{conn: conn} do
      conn = post(conn, ~p"/api/import/copymethat", %{recipes: []})
      response = json_response(conn, 200)

      assert response["imported"] == 0
      assert response["failed"] == 0
    end

    test "returns 400 for invalid input", %{conn: conn} do
      conn = post(conn, ~p"/api/import/copymethat", %{invalid: "data"})
      assert json_response(conn, 400)["error"]
    end

    test "returns 401 without authentication" do
      conn =
        build_conn()
        |> post(~p"/api/import/copymethat", %{recipes: []})

      assert json_response(conn, 401)
    end
  end
end
