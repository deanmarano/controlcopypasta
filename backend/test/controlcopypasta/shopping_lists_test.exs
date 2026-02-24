defmodule Controlcopypasta.ShoppingListsTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.ShoppingLists
  alias Controlcopypasta.ShoppingLists.{ShoppingList, ShoppingListItem}

  import Controlcopypasta.AccountsFixtures
  import Controlcopypasta.RecipesFixtures
  import Controlcopypasta.ShoppingListsFixtures

  describe "list_shopping_lists_for_user/2" do
    test "returns only user's lists" do
      user = user_fixture()
      other_user = user_fixture()

      list = shopping_list_fixture(%{user: user})
      _other_list = shopping_list_fixture(%{user: other_user})

      results = ShoppingLists.list_shopping_lists_for_user(user.id)
      assert length(results) == 1
      assert hd(results).id == list.id
    end

    test "excludes archived lists by default" do
      user = user_fixture()
      _active_list = shopping_list_fixture(%{user: user})
      archived_list = shopping_list_fixture(%{user: user})
      {:ok, _} = ShoppingLists.archive_shopping_list(archived_list)

      results = ShoppingLists.list_shopping_lists_for_user(user.id)
      assert length(results) == 1
    end

    test "includes archived lists when requested" do
      user = user_fixture()
      _active_list = shopping_list_fixture(%{user: user})
      archived_list = shopping_list_fixture(%{user: user})
      {:ok, _} = ShoppingLists.archive_shopping_list(archived_list)

      results = ShoppingLists.list_shopping_lists_for_user(user.id, %{"archived" => "all"})
      assert length(results) == 2
    end
  end

  describe "get_shopping_list_for_user/2" do
    test "returns list with items ordered by category and check status" do
      user = user_fixture()
      list = shopping_list_fixture(%{user: user})

      {:ok, _} =
        ShoppingLists.create_item(%{
          shopping_list_id: list.id,
          display_text: "Milk",
          category: "dairy"
        })

      {:ok, checked_item} =
        ShoppingLists.create_item(%{
          shopping_list_id: list.id,
          display_text: "Bread",
          category: "bakery"
        })

      {:ok, _} = ShoppingLists.check_item(checked_item)

      result = ShoppingLists.get_shopping_list_for_user(user.id, list.id)
      assert result.id == list.id
      assert length(result.items) == 2
      # Unchecked items first
      assert hd(result.items).checked_at == nil
    end

    test "returns nil for other user's list" do
      user = user_fixture()
      other_user = user_fixture()
      list = shopping_list_fixture(%{user: other_user})

      assert ShoppingLists.get_shopping_list_for_user(user.id, list.id) == nil
    end
  end

  describe "create_shopping_list/1" do
    test "creates a shopping list with valid attributes" do
      user = user_fixture()

      assert {:ok, %ShoppingList{} = list} =
               ShoppingLists.create_shopping_list(%{
                 name: "Weekly Groceries",
                 user_id: user.id
               })

      assert list.name == "Weekly Groceries"
      assert list.user_id == user.id
      assert list.archived_at == nil
    end

    test "fails without required fields" do
      assert {:error, changeset} = ShoppingLists.create_shopping_list(%{})
      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "create_item/1" do
    test "creates an item with valid attributes" do
      list = shopping_list_fixture()

      assert {:ok, %ShoppingListItem{} = item} =
               ShoppingLists.create_item(%{
                 shopping_list_id: list.id,
                 display_text: "2 cups flour",
                 quantity: Decimal.new("2"),
                 unit: "cup",
                 raw_name: "flour",
                 category: "pantry"
               })

      assert item.display_text == "2 cups flour"
      assert Decimal.equal?(item.quantity, Decimal.new("2"))
      assert item.unit == "cup"
      assert item.category == "pantry"
    end

    test "validates category inclusion" do
      list = shopping_list_fixture()

      assert {:error, changeset} =
               ShoppingLists.create_item(%{
                 shopping_list_id: list.id,
                 display_text: "Test",
                 category: "invalid_category"
               })

      assert "is invalid" in errors_on(changeset).category
    end
  end

  describe "check_item/1 and uncheck_item/1" do
    test "marks item as checked with timestamp" do
      item = shopping_list_item_fixture()
      assert item.checked_at == nil

      {:ok, checked_item} = ShoppingLists.check_item(item)
      assert checked_item.checked_at != nil
    end

    test "unmarks item" do
      item = shopping_list_item_fixture()
      {:ok, checked_item} = ShoppingLists.check_item(item)
      {:ok, unchecked_item} = ShoppingLists.uncheck_item(checked_item)

      assert unchecked_item.checked_at == nil
    end
  end

  describe "clear_checked_items/1" do
    test "removes all checked items from list" do
      list = shopping_list_fixture()

      {:ok, item1} =
        ShoppingLists.create_item(%{
          shopping_list_id: list.id,
          display_text: "Item 1"
        })

      {:ok, item2} =
        ShoppingLists.create_item(%{
          shopping_list_id: list.id,
          display_text: "Item 2"
        })

      {:ok, _} = ShoppingLists.check_item(item1)

      {:ok, updated_list} = ShoppingLists.clear_checked_items(list)

      assert length(updated_list.items) == 1
      assert hd(updated_list.items).id == item2.id
    end
  end

  describe "add_items_from_recipe/3" do
    test "adds ingredients from recipe to shopping list" do
      user = user_fixture()
      list = shopping_list_fixture(%{user: user})

      recipe =
        recipe_fixture(%{
          user: user,
          ingredients: [
            %{"text" => "2 cups flour"},
            %{"text" => "3 eggs"}
          ]
        })

      {:ok, updated_list} = ShoppingLists.add_items_from_recipe(list, recipe.id)

      assert length(updated_list.items) == 2
      texts = Enum.map(updated_list.items, & &1.raw_name)
      assert "flour" in texts
      assert "eggs" in texts
    end

    test "applies scale factor to quantities" do
      user = user_fixture()
      list = shopping_list_fixture(%{user: user})

      recipe =
        recipe_fixture(%{
          user: user,
          ingredients: [%{"text" => "2 cups flour"}]
        })

      {:ok, updated_list} = ShoppingLists.add_items_from_recipe(list, recipe.id, 2.0)

      item = hd(updated_list.items)
      assert Decimal.equal?(item.quantity, Decimal.new("4.0"))
    end

    test "returns error for non-existent recipe" do
      list = shopping_list_fixture()

      assert {:error, :recipe_not_found} =
               ShoppingLists.add_items_from_recipe(list, Ecto.UUID.generate())
    end
  end

  describe "archive_shopping_list/1" do
    test "sets archived_at timestamp" do
      list = shopping_list_fixture()
      assert list.archived_at == nil

      {:ok, archived_list} = ShoppingLists.archive_shopping_list(list)
      assert archived_list.archived_at != nil
    end
  end

  describe "unarchive_shopping_list/1" do
    test "clears archived_at timestamp" do
      list = shopping_list_fixture()
      {:ok, archived_list} = ShoppingLists.archive_shopping_list(list)
      {:ok, unarchived_list} = ShoppingLists.unarchive_shopping_list(archived_list)

      assert unarchived_list.archived_at == nil
    end
  end
end
