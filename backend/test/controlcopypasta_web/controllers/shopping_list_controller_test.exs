defmodule ControlcopypastaWeb.ShoppingListControllerTest do
  use ControlcopypastaWeb.ConnCase, async: true

  import Controlcopypasta.AccountsFixtures
  import Controlcopypasta.RecipesFixtures
  import Controlcopypasta.ShoppingListsFixtures

  alias Controlcopypasta.ShoppingLists

  setup :setup_authenticated_conn

  describe "GET /api/shopping-lists (index)" do
    test "lists all shopping lists for authenticated user", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})

      conn = get(conn, ~p"/api/shopping-lists")
      response = json_response(conn, 200)

      assert length(response["data"]) == 1
      assert hd(response["data"])["id"] == list.id
    end

    test "does not list other users' lists", %{conn: conn} do
      other_user = user_fixture()
      _other_list = shopping_list_fixture(%{user: other_user})

      conn = get(conn, ~p"/api/shopping-lists")
      response = json_response(conn, 200)

      assert response["data"] == []
    end

    test "returns 401 without authentication" do
      conn = build_conn() |> get(~p"/api/shopping-lists")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/shopping-lists (create)" do
    test "creates shopping list with valid data", %{conn: conn} do
      conn = post(conn, ~p"/api/shopping-lists", %{shopping_list: %{name: "Weekly Groceries"}})
      response = json_response(conn, 201)

      assert response["data"]["name"] == "Weekly Groceries"
      assert response["data"]["id"]
    end

    test "returns errors for invalid data", %{conn: conn} do
      conn = post(conn, ~p"/api/shopping-lists", %{shopping_list: %{name: ""}})
      response = json_response(conn, 422)

      assert response["errors"]
    end
  end

  describe "GET /api/shopping-lists/:id (show)" do
    test "returns shopping list with items", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})
      _item = shopping_list_item_fixture(%{shopping_list: list})

      conn = get(conn, ~p"/api/shopping-lists/#{list.id}")
      response = json_response(conn, 200)

      assert response["data"]["id"] == list.id
      assert response["data"]["items"]
      assert response["data"]["items_by_category"]
      assert response["data"]["total_count"] == 1
    end

    test "returns 404 for other user's list", %{conn: conn} do
      other_user = user_fixture()
      list = shopping_list_fixture(%{user: other_user})

      conn = get(conn, ~p"/api/shopping-lists/#{list.id}")
      assert json_response(conn, 404)
    end
  end

  describe "PUT /api/shopping-lists/:id (update)" do
    test "updates shopping list name", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})

      conn = put(conn, ~p"/api/shopping-lists/#{list.id}", %{shopping_list: %{name: "New Name"}})
      response = json_response(conn, 200)

      assert response["data"]["name"] == "New Name"
    end

    test "returns 404 for other user's list", %{conn: conn} do
      other_user = user_fixture()
      list = shopping_list_fixture(%{user: other_user})

      conn = put(conn, ~p"/api/shopping-lists/#{list.id}", %{shopping_list: %{name: "New"}})
      assert json_response(conn, 404)
    end
  end

  describe "DELETE /api/shopping-lists/:id (delete)" do
    test "deletes shopping list", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})

      conn = delete(conn, ~p"/api/shopping-lists/#{list.id}")
      assert response(conn, 204)

      assert ShoppingLists.get_shopping_list(list.id) == nil
    end

    test "returns 404 for other user's list", %{conn: conn} do
      other_user = user_fixture()
      list = shopping_list_fixture(%{user: other_user})

      conn = delete(conn, ~p"/api/shopping-lists/#{list.id}")
      assert json_response(conn, 404)
    end
  end

  describe "POST /api/shopping-lists/:id/archive" do
    test "archives shopping list", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})

      conn = post(conn, ~p"/api/shopping-lists/#{list.id}/archive")
      response = json_response(conn, 200)

      assert response["data"]["archived_at"]
    end
  end

  describe "POST /api/shopping-lists/:id/clear-checked" do
    test "removes checked items", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})
      item1 = shopping_list_item_fixture(%{shopping_list: list})
      _item2 = shopping_list_item_fixture(%{shopping_list: list})
      {:ok, _} = ShoppingLists.check_item(item1)

      conn = post(conn, ~p"/api/shopping-lists/#{list.id}/clear-checked")
      response = json_response(conn, 200)

      assert response["data"]["total_count"] == 1
    end
  end

  describe "POST /api/shopping-lists/:id/add-recipe" do
    test "adds recipe ingredients to list", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})
      recipe = recipe_fixture(%{
        user: user,
        ingredients: [
          %{"text" => "2 cups flour"},
          %{"text" => "1 cup sugar"}
        ]
      })

      conn = post(conn, ~p"/api/shopping-lists/#{list.id}/add-recipe", %{recipe_id: recipe.id})
      response = json_response(conn, 200)

      assert response["data"]["total_count"] == 2
    end

    test "applies scale factor", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})
      recipe = recipe_fixture(%{
        user: user,
        ingredients: [%{"text" => "1 cup flour"}]
      })

      conn = post(conn, ~p"/api/shopping-lists/#{list.id}/add-recipe", %{
        recipe_id: recipe.id,
        scale: 2.0
      })
      response = json_response(conn, 200)

      item = hd(response["data"]["items"])
      assert item["quantity"] == 2
    end

    test "returns 404 for non-existent recipe", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})

      conn = post(conn, ~p"/api/shopping-lists/#{list.id}/add-recipe", %{
        recipe_id: Ecto.UUID.generate()
      })
      assert json_response(conn, 404)
    end
  end

  describe "POST /api/shopping-lists/:id/items (create_item)" do
    test "creates item manually", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})

      conn = post(conn, ~p"/api/shopping-lists/#{list.id}/items", %{
        item: %{display_text: "2 avocados", category: "produce"}
      })
      response = json_response(conn, 201)

      assert response["data"]["display_text"] == "2 avocados"
      assert response["data"]["category"] == "produce"
    end
  end

  describe "PUT /api/shopping-lists/:id/items/:item_id (update_item)" do
    test "updates item", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})
      item = shopping_list_item_fixture(%{shopping_list: list})

      conn = put(conn, ~p"/api/shopping-lists/#{list.id}/items/#{item.id}", %{
        item: %{notes: "Get organic if available"}
      })
      response = json_response(conn, 200)

      assert response["data"]["notes"] == "Get organic if available"
    end
  end

  describe "DELETE /api/shopping-lists/:id/items/:item_id (delete_item)" do
    test "deletes item", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})
      item = shopping_list_item_fixture(%{shopping_list: list})

      conn = delete(conn, ~p"/api/shopping-lists/#{list.id}/items/#{item.id}")
      assert response(conn, 204)

      assert ShoppingLists.get_item(item.id) == nil
    end
  end

  describe "POST /api/shopping-lists/:id/items/:item_id/check" do
    test "marks item as checked", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})
      item = shopping_list_item_fixture(%{shopping_list: list})

      conn = post(conn, ~p"/api/shopping-lists/#{list.id}/items/#{item.id}/check")
      response = json_response(conn, 200)

      assert response["data"]["checked_at"]
    end
  end

  describe "POST /api/shopping-lists/:id/items/:item_id/uncheck" do
    test "marks item as unchecked", %{conn: conn, user: user} do
      list = shopping_list_fixture(%{user: user})
      item = shopping_list_item_fixture(%{shopping_list: list})
      {:ok, item} = ShoppingLists.check_item(item)

      conn = post(conn, ~p"/api/shopping-lists/#{list.id}/items/#{item.id}/uncheck")
      response = json_response(conn, 200)

      assert response["data"]["checked_at"] == nil
    end
  end
end
