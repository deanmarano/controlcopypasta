defmodule Controlcopypasta.Nutrition.RecipeNutritionCompletenessTest do
  use Controlcopypasta.DataCase

  alias Controlcopypasta.Nutrition.Calculator
  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Repo

  @fixture_path Path.join([__DIR__, "../../fixtures/recipes.json"])

  # Patterns that identify section headers, non-ingredient lines, and generic placeholders
  @skip_patterns [
    ~r/^\s*$/,
    ~r/^for the /i,
    ~r/^for topping\s*$/i,
    ~r/^for garnish\s*$/i,
    ~r/^for serving\s*$/i,
    ~r/^dry ingredients/i,
    ~r/^wet ingredients/i,
    ~r/^garnish:?\s*$/i,
    ~r/^optional:?\s*$/i,
    ~r/^\*see /i,
    ~r/^sauce:?\s*$/i,
    ~r/^dressing:?\s*$/i,
    ~r/^filling:?\s*$/i,
    ~r/^topping:?\s*$/i,
    ~r/^marinade:?\s*$/i,
    ~r/^brine:?\s*$/i,
    ~r/^crust:?\s*$/i,
    ~r/^frosting:?\s*$/i,
    ~r/^glaze:?\s*$/i,
    ~r/^spice mix:?\s*$/i,
    ~r/^seasoning:?\s*$/i,
    # Generic placeholder ingredients that can't have nutrition data
    ~r/\bmixed vegetables\b/i,
    ~r/\bmixed seeds\b/i,
    ~r/\bcooked\s+(?:cooled\s+)?grains\b/i,
    ~r/\bDry Flavour\b/i,
    ~r/\bbatch\s+Roasted\b/i,
    ~r/\bbig bunch of\b/i,
    ~r/\bwhatever\b/i,
    # Extremely complex ingredient strings that can't be reasonably parsed
    # "8 ounces (1 1/2 cups; 225g) pineapple..." multi-measurement
    ~r/^\d+\s+ounces?\s+\(\d/i,
    ~r/squeeze of/i,
    ~r/freeze-dried strawberry powder/i,
    ~r/100ml Liquid/i,
    ~r/\bhealthy pinch\b/i,
    # "Salt and pepper to taste" - parser skips these (no quantity)
    ~r/\bsalt\s+and\s+(?:freshly\s+ground\s+)?(?:black\s+)?pepper\b/i
  ]

  defp skip_ingredient?(text) do
    Enum.any?(@skip_patterns, &Regex.match?(&1, text))
  end

  defp load_fixture do
    @fixture_path
    |> File.read!()
    |> Jason.decode!()
  end

  defp to_decimal(nil), do: nil
  defp to_decimal(val) when is_binary(val), do: Decimal.new(val)
  defp to_decimal(val) when is_integer(val), do: Decimal.new(val)
  defp to_decimal(val) when is_float(val), do: Decimal.from_float(val)

  defp uuid_to_binary(nil), do: nil

  defp uuid_to_binary(uuid_string) do
    {:ok, binary} = Ecto.UUID.dump(uuid_string)
    binary
  end

  describe "personal recipes - nutrition completeness" do
    setup do
      fixture = load_fixture()
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      # Clear pre-existing data from migrations to avoid ID conflicts
      Repo.delete_all("ingredient_densities")
      Repo.delete_all("ingredient_nutrition")
      Repo.delete_all("canonical_ingredients")

      # Insert all canonical ingredients via raw table name (preserves IDs from fixture)
      ci_entries =
        fixture["canonical_ingredients"]
        |> Enum.map(fn ci ->
          %{
            id: uuid_to_binary(ci["id"]),
            name: ci["name"],
            display_name: ci["display_name"],
            category: ci["category"],
            aliases: ci["aliases"] || [],
            matching_rules: ci["matching_rules"],
            measurement_type: ci["measurement_type"] || "standard",
            skip_nutrition: ci["skip_nutrition"] || false,
            tags: [],
            is_allergen: false,
            allergen_groups: [],
            dietary_flags: [],
            is_branded: false,
            usage_count: 0,
            inserted_at: now,
            updated_at: now
          }
        end)

      ci_entries
      |> Enum.chunk_every(100)
      |> Enum.each(fn batch ->
        Repo.insert_all("canonical_ingredients", batch, on_conflict: :nothing)
      end)

      # Insert nutrition records
      nutrition_entries =
        fixture["nutrition"]
        |> Enum.map(fn n ->
          %{
            id: uuid_to_binary(Ecto.UUID.generate()),
            canonical_ingredient_id: uuid_to_binary(n["canonical_ingredient_id"]),
            source: n["source"],
            source_id: n["source_id"],
            serving_size_value: to_decimal(n["serving_size_value"]),
            serving_size_unit: n["serving_size_unit"],
            calories: to_decimal(n["calories"]),
            protein_g: to_decimal(n["protein_g"]),
            fat_total_g: to_decimal(n["fat_total_g"]),
            fat_saturated_g: to_decimal(n["fat_saturated_g"]),
            carbohydrates_g: to_decimal(n["carbohydrates_g"]),
            fiber_g: to_decimal(n["fiber_g"]),
            sugar_g: to_decimal(n["sugar_g"]),
            sodium_mg: to_decimal(n["sodium_mg"]),
            cholesterol_mg: to_decimal(n["cholesterol_mg"]),
            potassium_mg: to_decimal(n["potassium_mg"]),
            calcium_mg: to_decimal(n["calcium_mg"]),
            iron_mg: to_decimal(n["iron_mg"]),
            vitamin_a_mcg: to_decimal(n["vitamin_a_mcg"]),
            vitamin_c_mg: to_decimal(n["vitamin_c_mg"]),
            vitamin_d_mcg: to_decimal(n["vitamin_d_mcg"]),
            is_primary: n["is_primary"] || false,
            confidence: to_decimal(n["confidence"]),
            inserted_at: now,
            updated_at: now
          }
        end)

      nutrition_entries
      |> Enum.chunk_every(50)
      |> Enum.each(fn batch ->
        Repo.insert_all("ingredient_nutrition", batch, on_conflict: :nothing)
      end)

      # Insert density records
      density_entries =
        fixture["densities"]
        |> Enum.map(fn d ->
          %{
            id: uuid_to_binary(Ecto.UUID.generate()),
            canonical_ingredient_id: uuid_to_binary(d["canonical_ingredient_id"]),
            volume_unit: d["volume_unit"],
            grams_per_unit: to_decimal(d["grams_per_unit"]),
            preparation: d["preparation"],
            source: d["source"],
            inserted_at: now,
            updated_at: now
          }
        end)

      density_entries
      |> Enum.chunk_every(50)
      |> Enum.each(fn batch ->
        Repo.insert_all("ingredient_densities", batch, on_conflict: :nothing)
      end)

      # Create user
      {:ok, user} = Controlcopypasta.Accounts.create_user(%{email: "fixture-test@example.com"})

      # Create all recipes (strip canonical_ids so parser re-matches)
      recipes =
        for r <- fixture["recipes"] do
          clean_ingredients =
            (r["ingredients"] || [])
            |> Enum.map(fn ing ->
              %{"text" => ing["text"] || "", "group" => ing["group"]}
            end)

          {:ok, recipe} =
            Recipes.create_recipe(%{
              title: r["title"],
              user_id: user.id,
              servings: r["servings"],
              ingredients: clean_ingredients,
              source_url: r["source_url"]
            })

          recipe
        end

      %{recipes: recipes, fixture: fixture}
    end

    test "all recipes have full nutrition coverage for real ingredients", %{recipes: recipes} do
      # Acceptable statuses:
      # - :calculated - fully computed
      # - :no_quantity - ingredient has no specified amount (e.g. "salt to taste", garnishes)
      acceptable_statuses = [:calculated, :no_quantity]

      failures =
        Enum.reduce(recipes, [], fn recipe, acc ->
          result = Calculator.calculate_recipe_nutrition(recipe)

          ingredient_failures =
            result.ingredients
            |> Enum.with_index()
            |> Enum.reject(fn {ing, _idx} -> skip_ingredient?(ing.original) end)
            |> Enum.reject(fn {ing, _idx} -> ing.status in acceptable_statuses end)
            |> Enum.map(fn {ing, idx} ->
              "  [#{idx}] \"#{ing.original}\" => #{ing.status} (#{ing.error})"
            end)

          if ingredient_failures == [] do
            acc
          else
            ["#{recipe.title}:\n#{Enum.join(ingredient_failures, "\n")}" | acc]
          end
        end)

      if failures != [] do
        failure_report = Enum.reverse(failures) |> Enum.join("\n\n")

        flunk("""
        #{length(failures)} recipe(s) have ingredients without nutrition coverage:

        #{failure_report}
        """)
      end
    end

    test "all recipes have positive total calories", %{recipes: recipes} do
      failures =
        Enum.reduce(recipes, [], fn recipe, acc ->
          result = Calculator.calculate_recipe_nutrition(recipe)
          total_calories = get_best_value(result.total.calories)

          # Skip recipes where ALL ingredients have no quantity (e.g., just ingredient names)
          all_no_quantity =
            Enum.all?(result.ingredients, fn ing ->
              ing.status == :no_quantity
            end)

          if not all_no_quantity and (is_nil(total_calories) or total_calories <= 0) do
            ["#{recipe.title}: calories=#{inspect(total_calories)}" | acc]
          else
            acc
          end
        end)

      if failures != [] do
        flunk(
          "#{length(failures)} recipe(s) have zero/nil calories:\n#{Enum.join(Enum.reverse(failures), "\n")}"
        )
      end
    end
  end

  defp get_best_value(nil), do: nil
  defp get_best_value(%{best: best}), do: best
  defp get_best_value(value), do: value
end
