defmodule ControlcopypastaWeb.AvoidedIngredientJSON do
  alias Controlcopypasta.Accounts.AvoidedIngredient

  def index(%{avoided_ingredients: avoided_ingredients}) do
    %{data: for(item <- avoided_ingredients, do: data(item))}
  end

  def show(%{avoided_ingredient: avoided_ingredient}) do
    %{data: data(avoided_ingredient)}
  end

  defp data(%AvoidedIngredient{} = item) do
    base = %{
      id: item.id,
      display_name: item.display_name,
      avoidance_type: item.avoidance_type,
      inserted_at: item.inserted_at
    }

    # Add type-specific fields
    base
    |> maybe_add_ingredient_fields(item)
    |> maybe_add_category_field(item)
    |> maybe_add_allergen_field(item)
    |> maybe_add_animal_field(item)
  end

  defp maybe_add_ingredient_fields(base, %{avoidance_type: "ingredient"} = item) do
    base
    |> Map.put(:canonical_name, item.canonical_name)
    |> Map.put(:canonical_ingredient_id, item.canonical_ingredient_id)
    |> maybe_add_canonical_ingredient(item)
  end

  defp maybe_add_ingredient_fields(base, _item), do: base

  defp maybe_add_canonical_ingredient(base, %{canonical_ingredient: %{id: _} = ci}) do
    Map.put(base, :canonical_ingredient, %{
      id: ci.id,
      name: ci.name,
      display_name: ci.display_name,
      category: ci.category
    })
  end

  defp maybe_add_canonical_ingredient(base, _item), do: base

  defp maybe_add_category_field(base, %{avoidance_type: "category", category: category} = item) do
    base
    |> Map.put(:category, category)
    |> Map.put(:exceptions, item.exceptions || [])
    |> Map.put(:exception_count, length(item.exceptions || []))
  end

  defp maybe_add_category_field(base, _item), do: base

  defp maybe_add_allergen_field(base, %{avoidance_type: "allergen", allergen_group: allergen_group} = item) do
    base
    |> Map.put(:allergen_group, allergen_group)
    |> Map.put(:exceptions, item.exceptions || [])
    |> Map.put(:exception_count, length(item.exceptions || []))
  end

  defp maybe_add_allergen_field(base, _item), do: base

  defp maybe_add_animal_field(base, %{avoidance_type: "animal", animal_type: animal_type} = item) do
    base
    |> Map.put(:animal_type, animal_type)
    |> Map.put(:exceptions, item.exceptions || [])
    |> Map.put(:exception_count, length(item.exceptions || []))
  end

  defp maybe_add_animal_field(base, _item), do: base
end
