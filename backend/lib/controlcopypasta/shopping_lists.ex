defmodule Controlcopypasta.ShoppingLists do
  @moduledoc """
  The ShoppingLists context for managing shopping lists and their items.
  """

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo
  alias Controlcopypasta.ShoppingLists.{ShoppingList, ShoppingListItem, QuantityCombiner}
  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Similarity.IngredientParser

  # Shopping Lists

  def list_shopping_lists_for_user(user_id, params \\ %{}) do
    ShoppingList
    |> where([l], l.user_id == ^user_id)
    |> apply_archived_filter(params)
    |> order_by([l], desc: l.updated_at)
    |> Repo.all()
  end

  def get_shopping_list(id) do
    ShoppingList
    |> preload(:items)
    |> Repo.get(id)
  end

  def get_shopping_list!(id) do
    ShoppingList
    |> preload(:items)
    |> Repo.get!(id)
  end

  def get_shopping_list_for_user(user_id, id) do
    ShoppingList
    |> where([l], l.user_id == ^user_id)
    |> preload(items: ^items_query())
    |> Repo.get(id)
  end

  defp items_query do
    from i in ShoppingListItem,
      order_by: [
        asc: fragment("CASE WHEN ? IS NULL THEN 0 ELSE 1 END", i.checked_at),
        asc: i.category,
        asc: i.inserted_at
      ]
  end

  def create_shopping_list(attrs \\ %{}) do
    %ShoppingList{}
    |> ShoppingList.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, list} -> {:ok, Repo.preload(list, :items)}
      error -> error
    end
  end

  def update_shopping_list(%ShoppingList{} = list, attrs) do
    list
    |> ShoppingList.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, list} -> {:ok, Repo.preload(list, :items, force: true)}
      error -> error
    end
  end

  def delete_shopping_list(%ShoppingList{} = list) do
    Repo.delete(list)
  end

  def archive_shopping_list(%ShoppingList{} = list) do
    list
    |> Ecto.Changeset.change(archived_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
    |> case do
      {:ok, list} -> {:ok, Repo.preload(list, :items, force: true)}
      error -> error
    end
  end

  def unarchive_shopping_list(%ShoppingList{} = list) do
    list
    |> Ecto.Changeset.change(archived_at: nil)
    |> Repo.update()
    |> case do
      {:ok, list} -> {:ok, Repo.preload(list, :items, force: true)}
      error -> error
    end
  end

  defp apply_archived_filter(query, %{"archived" => "true"}) do
    where(query, [l], not is_nil(l.archived_at))
  end

  defp apply_archived_filter(query, %{"archived" => "all"}) do
    query
  end

  defp apply_archived_filter(query, _params) do
    where(query, [l], is_nil(l.archived_at))
  end

  # Shopping List Items

  def get_item(id) do
    Repo.get(ShoppingListItem, id)
  end

  def get_item!(id) do
    Repo.get!(ShoppingListItem, id)
  end

  def get_item_for_list(list_id, item_id) do
    ShoppingListItem
    |> where([i], i.shopping_list_id == ^list_id and i.id == ^item_id)
    |> Repo.one()
  end

  def create_item(attrs \\ %{}) do
    %ShoppingListItem{}
    |> ShoppingListItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_item(%ShoppingListItem{} = item, attrs) do
    item
    |> ShoppingListItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_item(%ShoppingListItem{} = item) do
    Repo.delete(item)
  end

  def check_item(%ShoppingListItem{} = item) do
    item
    |> ShoppingListItem.check_changeset()
    |> Repo.update()
  end

  def uncheck_item(%ShoppingListItem{} = item) do
    item
    |> ShoppingListItem.uncheck_changeset()
    |> Repo.update()
  end

  def clear_checked_items(%ShoppingList{} = list) do
    from(i in ShoppingListItem,
      where: i.shopping_list_id == ^list.id and not is_nil(i.checked_at)
    )
    |> Repo.delete_all()

    {:ok, get_shopping_list!(list.id)}
  end

  # Add items from a recipe

  def add_items_from_recipe(%ShoppingList{} = list, recipe_id, scale \\ 1.0) do
    case Recipes.get_recipe(recipe_id) do
      nil ->
        {:error, :recipe_not_found}

      recipe ->
        # Get existing items for this list
        existing_items = list_items_for_list(list.id)

        # Process each ingredient from the recipe
        results =
          recipe.ingredients
          |> Enum.map(fn ingredient ->
            add_ingredient_to_list(list, ingredient, recipe_id, scale, existing_items)
          end)

        errors = Enum.filter(results, &match?({:error, _}, &1))

        if Enum.empty?(errors) do
          {:ok, get_shopping_list!(list.id)}
        else
          {:error, :partial_failure, errors}
        end
    end
  end

  defp list_items_for_list(list_id) do
    ShoppingListItem
    |> where([i], i.shopping_list_id == ^list_id)
    |> Repo.all()
  end

  defp add_ingredient_to_list(list, ingredient, recipe_id, scale, existing_items) do
    # Parse the ingredient
    parsed = IngredientParser.parse_ingredient_map(ingredient)

    # Build the new item attributes
    {quantity, unit} = extract_quantity_unit(parsed, scale)
    category = categorize_ingredient(parsed.name)

    new_attrs = %{
      shopping_list_id: list.id,
      display_text: format_display(quantity, unit, parsed.name),
      quantity: quantity,
      unit: unit,
      canonical_name: parsed.name,
      raw_name: parsed.name,
      category: category,
      source_recipe_ids: [recipe_id]
    }

    # Check if we can combine with an existing item
    case find_combinable_item(existing_items, new_attrs) do
      nil ->
        create_item(new_attrs)

      existing_item ->
        case QuantityCombiner.merge_items(existing_item, new_attrs) do
          {:ok, merged_attrs} ->
            update_item(existing_item, merged_attrs)

          {:incompatible, _reason} ->
            # Create as separate item
            create_item(new_attrs)
        end
    end
  end

  defp find_combinable_item(existing_items, new_attrs) do
    Enum.find(existing_items, fn item ->
      QuantityCombiner.can_combine?(item, %{
        canonical_ingredient_id: new_attrs[:canonical_ingredient_id],
        canonical_name: new_attrs[:canonical_name],
        raw_name: new_attrs[:raw_name]
      })
    end)
  end

  defp extract_quantity_unit(parsed, scale) do
    quantity =
      if parsed.quantity do
        parsed.quantity
        |> Decimal.from_float()
        |> Decimal.mult(Decimal.from_float(scale))
      else
        nil
      end

    {quantity, parsed.unit}
  end

  defp format_display(nil, _unit, name), do: name
  defp format_display(quantity, nil, name), do: "#{format_qty(quantity)} #{name}"
  defp format_display(quantity, unit, name), do: "#{format_qty(quantity)} #{unit} #{name}"

  defp format_qty(d) when is_struct(d, Decimal) do
    d
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
    |> String.replace(~r/\.0+$/, "")
  end
  defp format_qty(n), do: to_string(n)

  # Ingredient categorization

  @produce_keywords ~w(lettuce spinach kale arugula tomato onion garlic pepper carrot celery cucumber zucchini squash broccoli cauliflower potato sweet potato mushroom apple banana orange lemon lime avocado cilantro parsley basil mint ginger scallion leek cabbage corn peas beans asparagus)
  @dairy_keywords ~w(milk cream butter cheese yogurt sour cream cream cheese cottage cheese ricotta mozzarella parmesan cheddar feta goat cheese)
  @protein_keywords ~w(chicken beef pork lamb turkey bacon sausage ham salmon tuna shrimp fish steak ground meat tofu tempeh egg eggs)
  @bakery_keywords ~w(bread roll bun bagel croissant muffin cake pie pastry tortilla pita naan)
  @frozen_keywords ~w(frozen ice cream popsicle)
  @spices_keywords ~w(salt pepper cumin paprika cinnamon nutmeg oregano thyme rosemary sage bay leaves cloves cardamom coriander turmeric curry chili powder cayenne)
  @condiments_keywords ~w(ketchup mustard mayonnaise soy sauce hot sauce bbq sauce salsa vinegar oil olive oil sesame oil honey maple syrup)
  @beverages_keywords ~w(juice soda water coffee tea wine beer)

  defp categorize_ingredient(nil), do: "other"
  defp categorize_ingredient(name) do
    name_lower = String.downcase(name)

    cond do
      matches_any?(name_lower, @produce_keywords) -> "produce"
      matches_any?(name_lower, @dairy_keywords) -> "dairy"
      matches_any?(name_lower, @protein_keywords) -> "protein"
      matches_any?(name_lower, @bakery_keywords) -> "bakery"
      matches_any?(name_lower, @frozen_keywords) -> "frozen"
      matches_any?(name_lower, @spices_keywords) -> "spices"
      matches_any?(name_lower, @condiments_keywords) -> "condiments"
      matches_any?(name_lower, @beverages_keywords) -> "beverages"
      true -> "pantry"
    end
  end

  defp matches_any?(name, keywords) do
    Enum.any?(keywords, fn keyword ->
      String.contains?(name, keyword)
    end)
  end
end
