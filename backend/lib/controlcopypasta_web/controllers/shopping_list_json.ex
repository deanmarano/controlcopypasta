defmodule ControlcopypastaWeb.ShoppingListJSON do
  alias Controlcopypasta.ShoppingLists.{ShoppingList, ShoppingListItem}

  def index(%{shopping_lists: lists}) do
    %{data: for(list <- lists, do: list_data(list))}
  end

  def show(%{shopping_list: list}) do
    %{data: list_data_with_items(list)}
  end

  def show_item(%{item: item}) do
    %{data: item_data(item)}
  end

  def error(%{message: message}) do
    %{error: %{message: message}}
  end

  defp list_data(%ShoppingList{} = list) do
    %{
      id: list.id,
      name: list.name,
      archived_at: list.archived_at,
      inserted_at: list.inserted_at,
      updated_at: list.updated_at
    }
  end

  defp list_data_with_items(%ShoppingList{} = list) do
    items = list.items || []

    # Group items by category
    items_by_category =
      items
      |> Enum.group_by(& &1.category)
      |> Enum.map(fn {category, category_items} ->
        %{
          category: category,
          items: Enum.map(category_items, &item_data/1)
        }
      end)
      |> Enum.sort_by(& &1.category)

    # Count checked/unchecked
    checked_count = Enum.count(items, & &1.checked_at)
    total_count = length(items)

    list_data(list)
    |> Map.merge(%{
      items: Enum.map(items, &item_data/1),
      items_by_category: items_by_category,
      checked_count: checked_count,
      total_count: total_count
    })
  end

  defp item_data(%ShoppingListItem{} = item) do
    %{
      id: item.id,
      display_text: item.display_text,
      quantity: decimal_to_number(item.quantity),
      unit: item.unit,
      canonical_ingredient_id: item.canonical_ingredient_id,
      canonical_name: item.canonical_name,
      raw_name: item.raw_name,
      category: item.category,
      checked_at: item.checked_at,
      notes: item.notes,
      source_recipe_ids: item.source_recipe_ids,
      inserted_at: item.inserted_at,
      updated_at: item.updated_at
    }
  end

  defp decimal_to_number(nil), do: nil
  defp decimal_to_number(%Decimal{} = d) do
    # Convert to float if it has decimals, otherwise to integer
    float_val = Decimal.to_float(d)
    if float_val == trunc(float_val) do
      trunc(float_val)
    else
      Float.round(float_val, 2)
    end
  end
  defp decimal_to_number(n), do: n
end
