defmodule ControlcopypastaWeb.ShoppingListController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.ShoppingLists
  alias Controlcopypasta.ShoppingLists.{ShoppingList, ShoppingListItem}

  action_fallback ControlcopypastaWeb.FallbackController

  # Shopping List CRUD

  def index(conn, params) do
    user = conn.assigns.current_user
    lists = ShoppingLists.list_shopping_lists_for_user(user.id, params)
    render(conn, :index, shopping_lists: lists)
  end

  def create(conn, %{"shopping_list" => list_params}) do
    user = conn.assigns.current_user
    list_params = Map.put(list_params, "user_id", user.id)

    with {:ok, %ShoppingList{} = list} <- ShoppingLists.create_shopping_list(list_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/shopping-lists/#{list}")
      |> render(:show, shopping_list: list)
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case ShoppingLists.get_shopping_list_for_user(user.id, id) do
      nil -> {:error, :not_found}
      list -> render(conn, :show, shopping_list: list)
    end
  end

  def update(conn, %{"id" => id, "shopping_list" => list_params}) do
    user = conn.assigns.current_user

    case ShoppingLists.get_shopping_list_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      list ->
        with {:ok, %ShoppingList{} = list} <- ShoppingLists.update_shopping_list(list, list_params) do
          render(conn, :show, shopping_list: list)
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case ShoppingLists.get_shopping_list_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      list ->
        with {:ok, %ShoppingList{}} <- ShoppingLists.delete_shopping_list(list) do
          send_resp(conn, :no_content, "")
        end
    end
  end

  # Shopping List Actions

  def archive(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case ShoppingLists.get_shopping_list_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      list ->
        with {:ok, %ShoppingList{} = list} <- ShoppingLists.archive_shopping_list(list) do
          render(conn, :show, shopping_list: list)
        end
    end
  end

  def clear_checked(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case ShoppingLists.get_shopping_list_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      list ->
        with {:ok, %ShoppingList{} = list} <- ShoppingLists.clear_checked_items(list) do
          render(conn, :show, shopping_list: list)
        end
    end
  end

  def add_recipe(conn, %{"id" => id, "recipe_id" => recipe_id} = params) do
    user = conn.assigns.current_user
    scale = Map.get(params, "scale", 1.0) |> parse_float(1.0)

    case ShoppingLists.get_shopping_list_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      list ->
        case ShoppingLists.add_items_from_recipe(list, recipe_id, scale) do
          {:ok, %ShoppingList{} = list} ->
            render(conn, :show, shopping_list: list)

          {:error, :recipe_not_found} ->
            conn
            |> put_status(:not_found)
            |> render(:error, message: "Recipe not found")

          {:error, :partial_failure, _errors} ->
            # Still return success, some items were added
            updated_list = ShoppingLists.get_shopping_list!(id)
            render(conn, :show, shopping_list: updated_list)
        end
    end
  end

  # Shopping List Items

  def create_item(conn, %{"id" => id, "item" => item_params}) do
    user = conn.assigns.current_user

    case ShoppingLists.get_shopping_list_for_user(user.id, id) do
      nil ->
        {:error, :not_found}

      _list ->
        item_params = Map.put(item_params, "shopping_list_id", id)

        with {:ok, %ShoppingListItem{} = item} <- ShoppingLists.create_item(item_params) do
          conn
          |> put_status(:created)
          |> render(:show_item, item: item)
        end
    end
  end

  def update_item(conn, %{"id" => id, "item_id" => item_id, "item" => item_params}) do
    user = conn.assigns.current_user

    with list when not is_nil(list) <- ShoppingLists.get_shopping_list_for_user(user.id, id),
         item when not is_nil(item) <- ShoppingLists.get_item_for_list(id, item_id),
         {:ok, %ShoppingListItem{} = item} <- ShoppingLists.update_item(item, item_params) do
      render(conn, :show_item, item: item)
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def delete_item(conn, %{"id" => id, "item_id" => item_id}) do
    user = conn.assigns.current_user

    with list when not is_nil(list) <- ShoppingLists.get_shopping_list_for_user(user.id, id),
         item when not is_nil(item) <- ShoppingLists.get_item_for_list(id, item_id),
         {:ok, %ShoppingListItem{}} <- ShoppingLists.delete_item(item) do
      send_resp(conn, :no_content, "")
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def check_item(conn, %{"id" => id, "item_id" => item_id}) do
    user = conn.assigns.current_user

    with list when not is_nil(list) <- ShoppingLists.get_shopping_list_for_user(user.id, id),
         item when not is_nil(item) <- ShoppingLists.get_item_for_list(id, item_id),
         {:ok, %ShoppingListItem{} = item} <- ShoppingLists.check_item(item) do
      render(conn, :show_item, item: item)
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def uncheck_item(conn, %{"id" => id, "item_id" => item_id}) do
    user = conn.assigns.current_user

    with list when not is_nil(list) <- ShoppingLists.get_shopping_list_for_user(user.id, id),
         item when not is_nil(item) <- ShoppingLists.get_item_for_list(id, item_id),
         {:ok, %ShoppingListItem{} = item} <- ShoppingLists.uncheck_item(item) do
      render(conn, :show_item, item: item)
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  # Helpers

  defp parse_float(val, default) when is_binary(val) do
    case Float.parse(val) do
      {float, _} -> float
      :error -> default
    end
  end

  defp parse_float(val, _default) when is_float(val), do: val
  defp parse_float(val, _default) when is_integer(val), do: val / 1.0
  defp parse_float(_, default), do: default
end
