defmodule ControlcopypastaWeb.IngredientJSON do
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, BrandPackageSize, IngredientNutrition}

  @doc """
  Renders a list of ingredients.
  """
  def index(%{ingredients: ingredients}) do
    %{data: for(ingredient <- ingredients, do: ingredient_data(ingredient))}
  end

  @doc """
  Renders a single ingredient with package sizes and nutrition.
  """
  def show(%{ingredient: ingredient, package_sizes: package_sizes, nutrition: nutrition, all_nutrition: all_nutrition}) do
    data = ingredient_data(ingredient)
      |> Map.put(:package_sizes, Enum.map(package_sizes, &package_size_data/1))
      |> Map.put(:nutrition, if(nutrition, do: nutrition_data(nutrition), else: nil))
      |> Map.put(:all_nutrition, Enum.map(all_nutrition, &nutrition_data/1))

    %{data: data}
  end

  def show(%{ingredient: ingredient, package_sizes: package_sizes, nutrition: nutrition}) do
    data = ingredient_data(ingredient)
      |> Map.put(:package_sizes, Enum.map(package_sizes, &package_size_data/1))
      |> Map.put(:nutrition, if(nutrition, do: nutrition_data(nutrition), else: nil))
      |> Map.put(:all_nutrition, [])

    %{data: data}
  end

  def show(%{ingredient: ingredient, package_sizes: package_sizes}) do
    %{
      data: ingredient_data(ingredient)
      |> Map.put(:package_sizes, Enum.map(package_sizes, &package_size_data/1))
      |> Map.put(:nutrition, nil)
      |> Map.put(:all_nutrition, [])
    }
  end

  @doc """
  Renders package sizes for an ingredient.
  """
  def package_sizes(%{package_sizes: package_sizes}) do
    %{data: Enum.map(package_sizes, &package_size_data/1)}
  end

  @doc """
  Renders a scaling result.
  """
  def scale_result(%{result: result}) do
    %{data: scaling_data(result)}
  end

  @doc """
  Renders bulk scaling results.
  """
  def scale_bulk_result(%{results: results, scale_factor: scale_factor}) do
    %{
      data: %{
        scale_factor: scale_factor,
        ingredients: Enum.map(results, &scaling_data/1)
      }
    }
  end

  # Private helpers

  defp ingredient_data(%CanonicalIngredient{} = ingredient) do
    # Get primary nutrition from preloaded association if available
    nutrition = case ingredient.nutrition_sources do
      %Ecto.Association.NotLoaded{} -> nil
      [] -> nil
      [primary | _] -> nutrition_data(primary)
    end

    %{
      id: ingredient.id,
      name: ingredient.name,
      display_name: ingredient.display_name,
      category: ingredient.category,
      subcategory: ingredient.subcategory,
      tags: ingredient.tags,
      is_allergen: ingredient.is_allergen,
      allergen_groups: ingredient.allergen_groups,
      dietary_flags: ingredient.dietary_flags,
      aliases: ingredient.aliases,
      is_branded: ingredient.is_branded,
      brand: ingredient.brand,
      parent_company: ingredient.parent_company,
      image_url: ingredient.image_url,
      usage_count: ingredient.usage_count,
      nutrition: nutrition
    }
  end

  defp package_size_data(%BrandPackageSize{} = ps) do
    %{
      id: ps.id,
      package_type: ps.package_type,
      size_value: Decimal.to_float(ps.size_value),
      size_unit: ps.size_unit,
      label: ps.label,
      is_default: ps.is_default
    }
  end

  defp package_size_data(ps) when is_map(ps) do
    # Handle already-formatted package size maps from scale_with_package_context
    %{
      type: ps[:type] || ps["type"],
      size_value: ps[:size_value] || ps["size_value"],
      size_unit: ps[:size_unit] || ps["size_unit"],
      label: ps[:label] || ps["label"],
      is_default: ps[:is_default] || ps["is_default"]
    }
  end

  defp scaling_data(result) do
    %{
      scaled_quantity: result[:scaled_quantity],
      scaled_unit: result[:scaled_unit],
      total_volume: result[:total_volume],
      package_suggestion: result[:package_suggestion],
      packages_to_buy: result[:packages_to_buy],
      package_size: result[:package_size],
      available_packages: result[:available_packages] || [],
      original_name: result[:original_name]
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp nutrition_data(%IngredientNutrition{} = n) do
    %{
      source: n.source,
      source_name: n.source_name,
      source_url: n.source_url,
      serving_size_value: decimal_to_float(n.serving_size_value),
      serving_size_unit: n.serving_size_unit,
      serving_description: n.serving_description,
      is_primary: n.is_primary,

      # Macros
      calories: decimal_to_float(n.calories),
      protein_g: decimal_to_float(n.protein_g),
      fat_total_g: decimal_to_float(n.fat_total_g),
      fat_saturated_g: decimal_to_float(n.fat_saturated_g),
      fat_trans_g: decimal_to_float(n.fat_trans_g),
      fat_polyunsaturated_g: decimal_to_float(n.fat_polyunsaturated_g),
      fat_monounsaturated_g: decimal_to_float(n.fat_monounsaturated_g),
      carbohydrates_g: decimal_to_float(n.carbohydrates_g),
      fiber_g: decimal_to_float(n.fiber_g),
      sugar_g: decimal_to_float(n.sugar_g),
      sugar_added_g: decimal_to_float(n.sugar_added_g),

      # Minerals
      sodium_mg: decimal_to_float(n.sodium_mg),
      potassium_mg: decimal_to_float(n.potassium_mg),
      calcium_mg: decimal_to_float(n.calcium_mg),
      iron_mg: decimal_to_float(n.iron_mg),
      magnesium_mg: decimal_to_float(n.magnesium_mg),
      phosphorus_mg: decimal_to_float(n.phosphorus_mg),
      zinc_mg: decimal_to_float(n.zinc_mg),

      # Vitamins
      vitamin_a_mcg: decimal_to_float(n.vitamin_a_mcg),
      vitamin_c_mg: decimal_to_float(n.vitamin_c_mg),
      vitamin_d_mcg: decimal_to_float(n.vitamin_d_mcg),
      vitamin_e_mg: decimal_to_float(n.vitamin_e_mg),
      vitamin_k_mcg: decimal_to_float(n.vitamin_k_mcg),
      vitamin_b6_mg: decimal_to_float(n.vitamin_b6_mg),
      vitamin_b12_mcg: decimal_to_float(n.vitamin_b12_mcg),
      folate_mcg: decimal_to_float(n.folate_mcg),
      thiamin_mg: decimal_to_float(n.thiamin_mg),
      riboflavin_mg: decimal_to_float(n.riboflavin_mg),
      niacin_mg: decimal_to_float(n.niacin_mg),

      # Other
      cholesterol_mg: decimal_to_float(n.cholesterol_mg),
      water_g: decimal_to_float(n.water_g)
    }
  end

  defp decimal_to_float(nil), do: nil
  defp decimal_to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp decimal_to_float(n) when is_number(n), do: n
end
