defmodule Controlcopypasta.ShoppingListsFixtures do
  @moduledoc """
  Test helpers for creating shopping list entities.
  """

  def unique_list_name, do: "Shopping List #{System.unique_integer()}"

  def valid_shopping_list_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_list_name()
    })
  end

  def shopping_list_fixture(attrs \\ %{}) do
    user = attrs[:user] || Controlcopypasta.AccountsFixtures.user_fixture()

    {:ok, list} =
      attrs
      |> Map.delete(:user)
      |> valid_shopping_list_attributes()
      |> Map.put(:user_id, user.id)
      |> Controlcopypasta.ShoppingLists.create_shopping_list()

    list
  end

  def valid_item_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      display_text: "1 cup flour",
      quantity: Decimal.new("1"),
      unit: "cup",
      raw_name: "flour",
      category: "pantry"
    })
  end

  def shopping_list_item_fixture(attrs \\ %{}) do
    list = attrs[:shopping_list] || shopping_list_fixture()

    {:ok, item} =
      attrs
      |> Map.delete(:shopping_list)
      |> valid_item_attributes()
      |> Map.put(:shopping_list_id, list.id)
      |> Controlcopypasta.ShoppingLists.create_item()

    item
  end
end
