defmodule Mix.Tasks.ExportRecipeFixture do
  @moduledoc """
  Exports recipe and nutrition data for a user as a JSON fixture file.

  ## Usage

      mix export_recipe_fixture <email> <output_path>
      mix export_recipe_fixture <email> <output_path> --database-url <url>

  Example:

      mix export_recipe_fixture user@example.com test/fixtures/recipes.json
      mix export_recipe_fixture user@example.com test/fixtures/recipes.json --database-url postgres://user:pass@host/db
  """

  use Mix.Task

  require Logger

  import Ecto.Query

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, IngredientNutrition, IngredientDensity}

  @shortdoc "Export recipe + nutrition data as JSON fixture"

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} = OptionParser.parse(args, strict: [database_url: :string])

    case positional do
      [email, output_path] ->
        if db_url = opts[:database_url] do
          # Override repo config before app starts
          Application.put_env(:controlcopypasta, Repo,
            url: db_url,
            pool_size: 2
          )
        end

        Mix.Task.run("app.start")
        export(email, output_path)

      _ ->
        Mix.shell().error("Usage: mix export_recipe_fixture <email> <output_path> [--database-url <url>]")
    end
  end

  defp export(email, output_path) do
    user = Accounts.get_user_by_email(email)

    unless user do
      Mix.shell().error("User not found: #{email}")
      System.halt(1)
    end

    Logger.info("Exporting recipes for #{email}...")

    # Get all recipes for the user (no pagination)
    recipes =
      Recipe
      |> where([r], r.user_id == ^user.id)
      |> Repo.all()

    Logger.info("Found #{length(recipes)} recipes")

    # Collect all canonical ingredient IDs referenced in recipe ingredients
    canonical_ids =
      recipes
      |> Enum.flat_map(fn r -> r.ingredients || [] end)
      |> Enum.map(fn ing -> ing["canonical_id"] end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    Logger.info("Found #{length(canonical_ids)} referenced canonical ingredients")

    # Fetch all canonical ingredients (get ALL of them since matching needs the full lookup)
    canonical_ingredients = Repo.all(from(c in CanonicalIngredient))
    Logger.info("Exporting #{length(canonical_ingredients)} canonical ingredients")

    all_canonical_ids = Enum.map(canonical_ingredients, & &1.id)

    # Fetch nutrition for all canonicals
    nutrition =
      IngredientNutrition
      |> where([n], n.canonical_ingredient_id in ^all_canonical_ids)
      |> Repo.all()

    Logger.info("Found #{length(nutrition)} nutrition records")

    # Fetch densities for all canonicals
    densities =
      IngredientDensity
      |> where([d], d.canonical_ingredient_id in ^all_canonical_ids)
      |> Repo.all()

    Logger.info("Found #{length(densities)} density records")

    fixture = %{
      recipes: Enum.map(recipes, &serialize_recipe/1),
      canonical_ingredients: Enum.map(canonical_ingredients, &serialize_canonical/1),
      nutrition: Enum.map(nutrition, &serialize_nutrition/1),
      densities: Enum.map(densities, &serialize_density/1)
    }

    json = Jason.encode!(fixture, pretty: true)

    # Ensure directory exists
    output_path |> Path.dirname() |> File.mkdir_p!()
    File.write!(output_path, json)

    Logger.info("Wrote fixture to #{output_path} (#{byte_size(json)} bytes)")
  end

  defp serialize_recipe(recipe) do
    %{
      id: recipe.id,
      title: recipe.title,
      servings: recipe.servings,
      ingredients: recipe.ingredients || [],
      source_url: recipe.source_url
    }
  end

  defp serialize_canonical(c) do
    %{
      id: c.id,
      name: c.name,
      display_name: c.display_name,
      category: c.category,
      aliases: c.aliases || [],
      matching_rules: c.matching_rules,
      measurement_type: c.measurement_type,
      skip_nutrition: c.skip_nutrition
    }
  end

  defp serialize_nutrition(n) do
    %{
      id: n.id,
      canonical_ingredient_id: n.canonical_ingredient_id,
      source: n.source,
      source_id: n.source_id,
      serving_size_value: decimal_to_string(n.serving_size_value),
      serving_size_unit: n.serving_size_unit,
      calories: decimal_to_string(n.calories),
      protein_g: decimal_to_string(n.protein_g),
      fat_total_g: decimal_to_string(n.fat_total_g),
      fat_saturated_g: decimal_to_string(n.fat_saturated_g),
      carbohydrates_g: decimal_to_string(n.carbohydrates_g),
      fiber_g: decimal_to_string(n.fiber_g),
      sugar_g: decimal_to_string(n.sugar_g),
      sodium_mg: decimal_to_string(n.sodium_mg),
      cholesterol_mg: decimal_to_string(n.cholesterol_mg),
      potassium_mg: decimal_to_string(n.potassium_mg),
      calcium_mg: decimal_to_string(n.calcium_mg),
      iron_mg: decimal_to_string(n.iron_mg),
      vitamin_a_mcg: decimal_to_string(n.vitamin_a_mcg),
      vitamin_c_mg: decimal_to_string(n.vitamin_c_mg),
      vitamin_d_mcg: decimal_to_string(n.vitamin_d_mcg),
      is_primary: n.is_primary,
      confidence: decimal_to_string(n.confidence)
    }
  end

  defp serialize_density(d) do
    %{
      id: d.id,
      canonical_ingredient_id: d.canonical_ingredient_id,
      volume_unit: d.volume_unit,
      grams_per_unit: decimal_to_string(d.grams_per_unit),
      preparation: d.preparation,
      source: d.source
    }
  end

  defp decimal_to_string(nil), do: nil
  defp decimal_to_string(%Decimal{} = d), do: Decimal.to_string(d)
  defp decimal_to_string(other), do: to_string(other)
end
