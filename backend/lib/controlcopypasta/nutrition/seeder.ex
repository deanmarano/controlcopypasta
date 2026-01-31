defmodule Controlcopypasta.Nutrition.Seeder do
  @moduledoc """
  Seeds nutrition data from USDA FoodData Central.

  This module handles fetching nutrition data for all canonical ingredients
  from the USDA API and storing it in the database.

  ## Usage

      # Seed all ingredients without nutrition data
      Controlcopypasta.Nutrition.Seeder.seed_all()

      # Seed a specific ingredient
      Controlcopypasta.Nutrition.Seeder.seed_ingredient(ingredient)

      # Check coverage
      Controlcopypasta.Nutrition.Seeder.coverage_report()
  """

  require Logger

  import Ecto.Query

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, IngredientNutrition}
  alias Controlcopypasta.Nutrition.USDAClient
  alias Controlcopypasta.Nutrition.OpenFoodFactsClient
  alias Controlcopypasta.Nutrition.FatSecretClient
  alias Controlcopypasta.Nutrition.SpoonacularClient
  alias Controlcopypasta.Nutrition.StringSimilarity

  @doc """
  Seeds nutrition data for all ingredients that don't have it yet.

  Options:
  - `:delay_ms` - Delay between API calls (default 200ms to respect rate limits)
  - `:batch_size` - How many to process before showing progress (default 10)
  - `:dry_run` - If true, search but don't save (default false)
  """
  def seed_all(opts \\ []) do
    delay_ms = opts[:delay_ms] || 200
    batch_size = opts[:batch_size] || 10
    dry_run = opts[:dry_run] || false

    ingredients = Ingredients.list_ingredients_without_nutrition()
    total = length(ingredients)

    Logger.info("Starting nutrition seeding for #{total} ingredients (dry_run: #{dry_run})")

    results =
      ingredients
      |> Enum.with_index(1)
      |> Enum.map(fn {ingredient, index} ->
        if rem(index, batch_size) == 0 or index == total do
          Logger.info("Progress: #{index}/#{total} (#{Float.round(index / total * 100, 1)}%)")
        end

        result = seed_ingredient(ingredient, dry_run: dry_run)

        # Rate limiting
        unless index == total, do: Process.sleep(delay_ms)

        {ingredient.name, result}
      end)

    # Summarize results
    {successes, failures} = Enum.split_with(results, fn {_, result} -> match?({:ok, _}, result) end)

    Logger.info("""

    Seeding complete!
    ================
    Total: #{total}
    Success: #{length(successes)}
    Failed: #{length(failures)}
    """)

    if length(failures) > 0 do
      Logger.info("Failed ingredients:")
      Enum.each(failures, fn {name, {:error, reason}} ->
        Logger.info("  - #{name}: #{inspect(reason)}")
      end)
    end

    %{
      total: total,
      success: length(successes),
      failed: length(failures),
      failures: Enum.map(failures, fn {name, {:error, reason}} -> {name, reason} end)
    }
  end

  @doc """
  Seeds nutrition data for a single ingredient.
  """
  def seed_ingredient(%CanonicalIngredient{} = ingredient, opts \\ []) do
    dry_run = opts[:dry_run] || false

    # Build search query - use name, try variations if needed
    search_queries = build_search_queries(ingredient)

    # Try each query until we find a good match
    result = Enum.reduce_while(search_queries, {:error, :not_found}, fn query, _acc ->
      case USDAClient.search(query, page_size: 5) do
        {:ok, []} ->
          {:cont, {:error, :not_found}}

        {:ok, results} ->
          # Find best match
          case find_best_match(results, ingredient) do
            nil ->
              {:cont, {:error, :no_good_match}}

            match ->
              {:halt, {:ok, match}}
          end

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)

    case result do
      {:ok, match} ->
        Logger.debug("Found match for '#{ingredient.name}': #{match.description} (FDC: #{match.fdc_id})")

        if dry_run do
          {:ok, :dry_run}
        else
          fetch_and_save_nutrition(ingredient, match)
        end

      {:error, reason} ->
        Logger.debug("No match for '#{ingredient.name}': #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Generates a coverage report.
  """
  def coverage_report do
    stats = Ingredients.nutrition_coverage_stats()

    # Break down by source
    source_counts =
      Repo.all(
        from(n in IngredientNutrition,
          group_by: n.source,
          select: {n.source, count(n.id)}
        )
      )
      |> Map.new()

    # Break down by category
    category_coverage =
      Repo.all(
        from(ci in CanonicalIngredient,
          left_join: n in IngredientNutrition,
          on: n.canonical_ingredient_id == ci.id,
          group_by: ci.category,
          select: {ci.category, count(ci.id, :distinct), count(n.id, :distinct)}
        )
      )
      |> Enum.map(fn {cat, total, with_nutrition} ->
        pct = if total > 0, do: Float.round(with_nutrition / total * 100, 1), else: 0
        {cat || "uncategorized", total, with_nutrition, pct}
      end)
      |> Enum.sort_by(fn {_, _, _, pct} -> -pct end)

    %{
      overall: stats,
      by_source: source_counts,
      by_category: category_coverage
    }
  end

  # =============================================================================
  # Open Food Facts Seeding
  # =============================================================================

  @doc """
  Seeds nutrition data from Open Food Facts for ingredients without data.

  This is useful for branded products and items not in USDA.

  Options:
  - `:delay_ms` - Delay between API calls (default 500ms)
  - `:batch_size` - How many to process before showing progress (default 10)
  - `:dry_run` - If true, search but don't save (default false)
  """
  def seed_from_open_food_facts(opts \\ []) do
    delay_ms = opts[:delay_ms] || 500
    batch_size = opts[:batch_size] || 10
    dry_run = opts[:dry_run] || false

    ingredients = Ingredients.list_ingredients_without_nutrition()
    total = length(ingredients)

    Logger.info("Starting Open Food Facts seeding for #{total} ingredients (dry_run: #{dry_run})")

    results =
      ingredients
      |> Enum.with_index(1)
      |> Enum.map(fn {ingredient, index} ->
        if rem(index, batch_size) == 0 or index == total do
          Logger.info("Progress: #{index}/#{total} (#{Float.round(index / total * 100, 1)}%)")
        end

        result = seed_ingredient_from_off(ingredient, dry_run: dry_run)

        # Rate limiting
        unless index == total, do: Process.sleep(delay_ms)

        {ingredient.name, result}
      end)

    # Summarize results
    {successes, failures} = Enum.split_with(results, fn {_, result} -> match?({:ok, _}, result) end)

    Logger.info("""

    Open Food Facts seeding complete!
    =================================
    Total: #{total}
    Success: #{length(successes)}
    Failed: #{length(failures)}
    """)

    if length(failures) > 0 do
      Logger.info("Failed ingredients:")
      Enum.each(failures, fn {name, {:error, reason}} ->
        Logger.info("  - #{name}: #{inspect(reason)}")
      end)
    end

    %{
      total: total,
      success: length(successes),
      failed: length(failures),
      failures: Enum.map(failures, fn {name, {:error, reason}} -> {name, reason} end)
    }
  end

  @doc """
  Seeds nutrition for a single ingredient from Open Food Facts.
  """
  def seed_ingredient_from_off(%CanonicalIngredient{} = ingredient, opts \\ []) do
    dry_run = opts[:dry_run] || false

    search_queries = build_search_queries(ingredient)

    result = Enum.reduce_while(search_queries, {:error, :not_found}, fn query, _acc ->
      case OpenFoodFactsClient.search(query, page_size: 5) do
        {:ok, []} ->
          {:cont, {:error, :not_found}}

        {:ok, products} ->
          case find_best_off_match(products, ingredient) do
            nil ->
              {:cont, {:error, :no_good_match}}

            match ->
              {:halt, {:ok, match}}
          end

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)

    case result do
      {:ok, match} ->
        Logger.debug("Found OFF match for '#{ingredient.name}': #{match.product_name} (#{match.code})")

        if dry_run do
          {:ok, :dry_run}
        else
          save_off_nutrition(ingredient, match)
        end

      {:error, reason} ->
        Logger.debug("No OFF match for '#{ingredient.name}': #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Find best matching Open Food Facts product
  defp find_best_off_match(products, ingredient) do
    scored =
      products
      |> Enum.filter(fn p -> p.product_name != nil end)
      |> Enum.map(fn product ->
        score = calculate_off_match_score(product, ingredient)
        {product, score}
      end)
      |> Enum.filter(fn {_, score} -> score > 0.3 end)
      |> Enum.sort_by(fn {_, score} -> -score end)

    case scored do
      [{product, _score} | _] -> product
      [] -> nil
    end
  end

  defp calculate_off_match_score(product, ingredient) do
    product_name = String.downcase(product.product_name || "")
    name = String.downcase(ingredient.name)
    name_words = String.split(name)

    # Word match score
    word_matches = Enum.count(name_words, &String.contains?(product_name, &1))
    word_score = word_matches / max(length(name_words), 1)

    # Exact match bonus
    exact_bonus = if String.contains?(product_name, name), do: 0.3, else: 0

    # Has complete nutrition data bonus
    nutrition_bonus =
      if product.nutrients.calories && product.nutrients.protein_g && product.nutrients.carbohydrates_g do
        0.2
      else
        0
      end

    word_score + exact_bonus + nutrition_bonus
  end

  defp save_off_nutrition(ingredient, product) do
    nutrients = product.nutrients

    attrs = %{
      canonical_ingredient_id: ingredient.id,
      source: :open_food_facts,
      source_id: product.code,
      source_name: "Open Food Facts - #{product.brand || "Generic"}",
      source_url: "https://world.openfoodfacts.org/product/#{product.code}",
      serving_size_value: 100,
      serving_size_unit: "g",
      serving_description: product.serving_size,
      is_primary: true,

      calories: nutrients.calories,
      protein_g: nutrients.protein_g,
      fat_total_g: nutrients.fat_total_g,
      fat_saturated_g: nutrients.fat_saturated_g,
      fat_trans_g: nutrients.fat_trans_g,
      carbohydrates_g: nutrients.carbohydrates_g,
      fiber_g: nutrients.fiber_g,
      sugar_g: nutrients.sugar_g,
      sodium_mg: nutrients.sodium_mg,
      potassium_mg: nutrients.potassium_mg,
      calcium_mg: nutrients.calcium_mg,
      iron_mg: nutrients.iron_mg,
      vitamin_a_mcg: nutrients.vitamin_a_mcg,
      vitamin_c_mg: nutrients.vitamin_c_mg,
      vitamin_d_mcg: nutrients.vitamin_d_mcg,
      cholesterol_mg: nutrients.cholesterol_mg
    }

    # Also save image if available and ingredient doesn't have one
    if product.image_url && is_nil(ingredient.image_url) do
      Ingredients.update_canonical_ingredient(ingredient, %{image_url: product.image_url})
    end

    case Ingredients.create_nutrition(attrs) do
      {:ok, nutrition} ->
        {:ok, nutrition}

      {:error, changeset} ->
        {:error, {:save_failed, changeset.errors}}
    end
  end

  # =============================================================================
  # FatSecret Seeding (Branded Products)
  # =============================================================================

  @doc """
  Seeds nutrition data from FatSecret for branded ingredients.

  FatSecret is particularly good for US branded products.

  Options:
  - `:delay_ms` - Delay between API calls (default 500ms)
  - `:batch_size` - How many to process before showing progress (default 10)
  - `:dry_run` - If true, search but don't save (default false)
  - `:branded_only` - If true, only seed ingredients marked as branded (default false)
  """
  def seed_from_fatsecret(opts \\ []) do
    unless FatSecretClient.credentials_configured?() do
      Logger.error("FatSecret credentials not configured. Set FATSECRET_CLIENT_ID and FATSECRET_CLIENT_SECRET.")
      {:error, :credentials_missing}
    else
      delay_ms = opts[:delay_ms] || 500
      batch_size = opts[:batch_size] || 10
      dry_run = opts[:dry_run] || false
      branded_only = opts[:branded_only] || false

      ingredients =
        if branded_only do
          Ingredients.list_branded_ingredients_without_nutrition()
        else
          Ingredients.list_ingredients_without_nutrition()
        end

      total = length(ingredients)

      Logger.info("Starting FatSecret seeding for #{total} ingredients (dry_run: #{dry_run}, branded_only: #{branded_only})")

      results =
        ingredients
        |> Enum.with_index(1)
        |> Enum.map(fn {ingredient, index} ->
          if rem(index, batch_size) == 0 or index == total do
            Logger.info("Progress: #{index}/#{total} (#{Float.round(index / total * 100, 1)}%)")
          end

          result = seed_ingredient_from_fatsecret(ingredient, dry_run: dry_run)

          # Rate limiting
          unless index == total, do: Process.sleep(delay_ms)

          {ingredient.name, result}
        end)

      # Summarize results
      {successes, failures} = Enum.split_with(results, fn {_, result} -> match?({:ok, _}, result) end)

      Logger.info("""

      FatSecret seeding complete!
      ===========================
      Total: #{total}
      Success: #{length(successes)}
      Failed: #{length(failures)}
      """)

      if length(failures) > 0 do
        Logger.info("Failed ingredients (first 10):")
        failures
        |> Enum.take(10)
        |> Enum.each(fn {name, {:error, reason}} ->
          Logger.info("  - #{name}: #{inspect(reason)}")
        end)
      end

      %{
        total: total,
        success: length(successes),
        failed: length(failures),
        failures: Enum.map(failures, fn {name, {:error, reason}} -> {name, reason} end)
      }
    end
  end

  @doc """
  Seeds nutrition for a single ingredient from FatSecret.
  """
  def seed_ingredient_from_fatsecret(%CanonicalIngredient{} = ingredient, opts \\ []) do
    dry_run = opts[:dry_run] || false

    search_queries = build_search_queries(ingredient)

    result = Enum.reduce_while(search_queries, {:error, :not_found}, fn query, _acc ->
      case FatSecretClient.search(query, max_results: 10) do
        {:ok, []} ->
          {:cont, {:error, :not_found}}

        {:ok, foods} ->
          case find_best_fatsecret_match(foods, ingredient) do
            nil ->
              {:cont, {:error, :no_good_match}}

            match ->
              {:halt, {:ok, match}}
          end

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)

    case result do
      {:ok, match} ->
        Logger.debug("Found FatSecret match for '#{ingredient.name}': #{match.food_name} (ID: #{match.food_id})")

        if dry_run do
          {:ok, :dry_run}
        else
          fetch_and_save_fatsecret_nutrition(ingredient, match)
        end

      {:error, reason} ->
        Logger.debug("No FatSecret match for '#{ingredient.name}': #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Find best matching FatSecret food
  defp find_best_fatsecret_match(foods, ingredient) do
    scored =
      foods
      |> Enum.filter(fn f -> f.food_name != nil end)
      |> Enum.map(fn food ->
        score = calculate_fatsecret_match_score(food, ingredient)
        {food, score}
      end)
      |> Enum.filter(fn {_, score} -> score > 0.3 end)
      |> Enum.sort_by(fn {_, score} -> -score end)

    case scored do
      [{food, _score} | _] -> food
      [] -> nil
    end
  end

  defp calculate_fatsecret_match_score(food, ingredient) do
    food_name = String.downcase(food.food_name || "")
    name = String.downcase(ingredient.name)
    name_words = String.split(name)

    # Word match score
    word_matches = Enum.count(name_words, &String.contains?(food_name, &1))
    word_score = word_matches / max(length(name_words), 1)

    # Exact match bonus
    exact_bonus = if String.contains?(food_name, name), do: 0.3, else: 0

    # Branded bonus - prefer branded if ingredient is branded
    brand_bonus =
      cond do
        food.brand_name && ingredient.is_branded -> 0.3
        food.brand_name && not ingredient.is_branded -> 0.1
        true -> 0
      end

    word_score + exact_bonus + brand_bonus
  end

  defp fetch_and_save_fatsecret_nutrition(ingredient, match) do
    case FatSecretClient.get_food(match.food_id) do
      {:ok, food_data} ->
        save_fatsecret_nutrition(ingredient, food_data)

      {:error, reason} ->
        {:error, {:fetch_failed, reason}}
    end
  end

  defp save_fatsecret_nutrition(ingredient, food) do
    nutrients = food.nutrients

    # Normalize to per 100g if needed
    {normalized_nutrients, serving_value, serving_unit} =
      normalize_fatsecret_nutrients(nutrients, food.serving_size_value, food.serving_size_unit)

    attrs = %{
      canonical_ingredient_id: ingredient.id,
      source: :fatsecret,
      source_id: food.food_id,
      source_name: "FatSecret - #{food.brand_name || "Generic"}",
      source_url: food.food_url,
      serving_size_value: serving_value,
      serving_size_unit: serving_unit,
      serving_description: food.serving_description,
      is_primary: true,
      retrieved_at: DateTime.utc_now(),
      last_checked_at: DateTime.utc_now(),

      calories: normalized_nutrients.calories,
      protein_g: normalized_nutrients.protein_g,
      fat_total_g: normalized_nutrients.fat_total_g,
      fat_saturated_g: normalized_nutrients.fat_saturated_g,
      fat_trans_g: normalized_nutrients.fat_trans_g,
      fat_polyunsaturated_g: normalized_nutrients.fat_polyunsaturated_g,
      fat_monounsaturated_g: normalized_nutrients.fat_monounsaturated_g,
      carbohydrates_g: normalized_nutrients.carbohydrates_g,
      fiber_g: normalized_nutrients.fiber_g,
      sugar_g: normalized_nutrients.sugar_g,
      sodium_mg: normalized_nutrients.sodium_mg,
      potassium_mg: normalized_nutrients.potassium_mg,
      calcium_mg: normalized_nutrients.calcium_mg,
      iron_mg: normalized_nutrients.iron_mg,
      cholesterol_mg: normalized_nutrients.cholesterol_mg,
      vitamin_a_mcg: normalized_nutrients.vitamin_a_mcg,
      vitamin_c_mg: normalized_nutrients.vitamin_c_mg,
      vitamin_d_mcg: normalized_nutrients.vitamin_d_mcg
    }

    case Ingredients.create_nutrition(attrs) do
      {:ok, nutrition} ->
        {:ok, nutrition}

      {:error, changeset} ->
        {:error, {:save_failed, changeset.errors}}
    end
  end

  # Normalize FatSecret nutrients to per 100g
  defp normalize_fatsecret_nutrients(nutrients, serving_value, serving_unit) do
    # If already per 100g, return as-is
    if serving_unit == "g" and serving_value == 100 do
      {nutrients, 100, "g"}
    else
      # Try to normalize to 100g
      grams = convert_to_grams(serving_value, serving_unit)

      if grams && grams > 0 do
        multiplier = 100 / grams

        normalized = %{
          calories: maybe_multiply(nutrients.calories, multiplier),
          protein_g: maybe_multiply(nutrients.protein_g, multiplier),
          fat_total_g: maybe_multiply(nutrients.fat_total_g, multiplier),
          fat_saturated_g: maybe_multiply(nutrients.fat_saturated_g, multiplier),
          fat_trans_g: maybe_multiply(nutrients.fat_trans_g, multiplier),
          fat_polyunsaturated_g: maybe_multiply(nutrients.fat_polyunsaturated_g, multiplier),
          fat_monounsaturated_g: maybe_multiply(nutrients.fat_monounsaturated_g, multiplier),
          carbohydrates_g: maybe_multiply(nutrients.carbohydrates_g, multiplier),
          fiber_g: maybe_multiply(nutrients.fiber_g, multiplier),
          sugar_g: maybe_multiply(nutrients.sugar_g, multiplier),
          sodium_mg: maybe_multiply(nutrients.sodium_mg, multiplier),
          potassium_mg: maybe_multiply(nutrients.potassium_mg, multiplier),
          calcium_mg: maybe_multiply(nutrients.calcium_mg, multiplier),
          iron_mg: maybe_multiply(nutrients.iron_mg, multiplier),
          cholesterol_mg: maybe_multiply(nutrients.cholesterol_mg, multiplier),
          vitamin_a_mcg: maybe_multiply(nutrients.vitamin_a_mcg, multiplier),
          vitamin_c_mg: maybe_multiply(nutrients.vitamin_c_mg, multiplier),
          vitamin_d_mcg: maybe_multiply(nutrients.vitamin_d_mcg, multiplier)
        }

        {normalized, 100, "g"}
      else
        # Can't normalize, keep original
        {nutrients, serving_value, serving_unit}
      end
    end
  end

  defp convert_to_grams(value, unit) when is_number(value) do
    case unit do
      "g" -> value
      "ml" -> value  # Approximate for liquids
      "oz" -> value * 28.35
      _ -> nil
    end
  end

  defp convert_to_grams(_, _), do: nil

  defp maybe_multiply(nil, _), do: nil
  defp maybe_multiply(value, multiplier), do: Float.round(value * multiplier, 2)

  # =============================================================================
  # Image Seeding (Spoonacular)
  # =============================================================================

  @doc """
  Seeds images for ingredients from Spoonacular.

  Spoonacular has a database of 2600+ ingredient images.

  Options:
  - `:delay_ms` - Delay between API calls (default 1000ms for rate limit)
  - `:batch_size` - How many to process before showing progress (default 10)
  - `:size` - Image size: "100x100", "250x250", "500x500" (default "250x250")

  Note: Free tier is 150 requests/day, so you may need to run this over multiple days.
  """
  def seed_images(opts \\ []) do
    unless SpoonacularClient.api_key_configured?() do
      Logger.error("Spoonacular API key not configured. Set SPOONACULAR_API_KEY environment variable.")
      {:error, :api_key_missing}
    else
      delay_ms = opts[:delay_ms] || 1000
      batch_size = opts[:batch_size] || 10
      size = opts[:size] || "250x250"
      limit = opts[:limit] || 150  # Free tier daily limit

      # Get ingredients without images, ordered by recipe usage (most used first)
      Logger.info("Calculating ingredient usage in recipes...")
      ingredients = Ingredients.list_ingredients_without_images_by_usage(limit)

      total = length(ingredients)
      Logger.info("Searching for images for #{total} ingredients (limit: #{limit})")

      results =
        ingredients
        |> Enum.with_index(1)
        |> Enum.reduce_while([], fn {ingredient, index}, acc ->
          if rem(index, batch_size) == 0 or index == total do
            Logger.info("Progress: #{index}/#{total} (#{Float.round(index / total * 100, 1)}%)")
          end

          result = search_and_save_spoonacular_image(ingredient, size)

          # Rate limiting (1 req/sec for free tier)
          unless index == total, do: Process.sleep(delay_ms)

          case result do
            {:error, :daily_limit_exceeded} ->
              Logger.warning("Daily limit reached at ingredient #{index}")
              {:halt, [{ingredient.name, result} | acc]}

            _ ->
              {:cont, [{ingredient.name, result} | acc]}
          end
        end)

      results = Enum.reverse(results)

      # Summarize
      {successes, failures} = Enum.split_with(results, fn {_, result} -> match?({:ok, _}, result) end)

      Logger.info("""

      Image seeding complete!
      ======================
      Processed: #{length(results)}
      Success: #{length(successes)}
      Failed: #{length(failures)}
      Remaining: #{Repo.aggregate(from(ci in CanonicalIngredient, where: is_nil(ci.image_url)), :count)}
      """)

      %{
        processed: length(results),
        success: length(successes),
        failed: length(failures)
      }
    end
  end

  defp search_and_save_spoonacular_image(ingredient, size) do
    # Try name first, then aliases
    queries = [ingredient.name | (ingredient.aliases || [])]

    result = Enum.reduce_while(queries, {:error, :not_found}, fn query, _acc ->
      case SpoonacularClient.search(query, number: 1) do
        {:ok, []} ->
          {:cont, {:error, :not_found}}

        {:ok, [match | _]} ->
          image_url = SpoonacularClient.build_image_url(match.image, size)
          {:halt, {:ok, image_url}}

        {:error, :daily_limit_exceeded} = err ->
          {:halt, err}

        {:error, _reason} ->
          {:cont, {:error, :not_found}}
      end
    end)

    case result do
      {:ok, image_url} ->
        Logger.debug("Found image for '#{ingredient.name}': #{image_url}")
        Ingredients.update_canonical_ingredient(ingredient, %{image_url: image_url})

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Build search queries from ingredient, trying different variations
  defp build_search_queries(%CanonicalIngredient{} = ingredient) do
    base_queries = [ingredient.name]

    # Add aliases as fallback queries
    alias_queries = ingredient.aliases || []

    # Add simplified version (remove descriptors)
    simplified =
      ingredient.name
      |> String.replace(~r/\s+(fresh|dried|frozen|canned|raw|cooked)\s*/, " ")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()

    all_queries = (base_queries ++ [simplified] ++ alias_queries)
    |> Enum.uniq()
    |> Enum.reject(&(&1 == "" or is_nil(&1)))

    all_queries
  end

  # Find the best matching food from search results
  defp find_best_match(results, ingredient) do
    # Score each result and pick the best
    scored =
      results
      |> Enum.map(fn result ->
        score = calculate_match_score(result, ingredient)
        {result, score}
      end)
      |> Enum.filter(fn {_, score} -> score >= 0.5 end)  # Raised threshold from 0.3
      |> Enum.sort_by(fn {_, score} -> -score end)

    case scored do
      [{result, score} | _] ->
        Logger.debug("Best match for '#{ingredient.name}': #{result.description} (score: #{Float.round(score, 2)})")
        result
      [] ->
        Logger.debug("No good match for '#{ingredient.name}' (all scores below 0.5)")
        nil
    end
  end

  # Calculate how well a USDA result matches our ingredient
  # Uses StringSimilarity for more accurate matching
  defp calculate_match_score(result, ingredient) do
    description = String.downcase(result.description)
    name = String.downcase(ingredient.name)

    # Use comprehensive string similarity score
    similarity_score = StringSimilarity.match_score(name, description)

    # Require either:
    # 1. Query is a substring of description, OR
    # 2. High Jaro-Winkler similarity (> 0.85), OR
    # 3. All query words are in description
    {_matched_words, total_words, word_coverage} = StringSimilarity.word_overlap(name, description)
    jw_score = StringSimilarity.jaro_winkler(name, description)
    is_substring = StringSimilarity.meaningful_substring?(name, description)

    base_requirement_met =
      is_substring or
      jw_score >= 0.85 or
      word_coverage >= 0.9

    # If base requirement not met, heavily penalize
    base_penalty = if base_requirement_met, do: 0.0, else: 0.4

    # Bonus for Foundation/SR Legacy data types (more reliable)
    type_bonus =
      case result.data_type do
        "Foundation" -> 0.15
        "SR Legacy" -> 0.10
        _ -> 0
      end

    # Penalty for branded items when we have non-branded ingredient
    brand_penalty =
      if result.data_type == "Branded" and not ingredient.is_branded do
        0.15
      else
        0
      end

    # Penalty for very long descriptions (usually too specific)
    length_penalty =
      if String.length(description) > 100 do
        0.1
      else
        0
      end

    # Penalty if description has many unrelated words
    unrelated_penalty =
      if StringSimilarity.has_unrelated_words?(name, description) do
        0.2
      else
        0
      end

    # Extra penalty if query words are a small fraction of description
    # e.g., "apple" matching "Apple, raw, with skin, USDA commodity" should be penalized
    desc_words = description |> String.split(~r/[\s,]+/) |> length()
    disproportion_penalty =
      if total_words <= 2 and desc_words > 6 and not is_substring do
        0.15
      else
        0
      end

    final_score = similarity_score + type_bonus - brand_penalty - length_penalty -
                  unrelated_penalty - base_penalty - disproportion_penalty

    # Clamp to 0.0-1.0
    max(0.0, min(1.0, final_score))
  end

  # Fetch full nutrition data and save to database
  defp fetch_and_save_nutrition(ingredient, match) do
    case USDAClient.get_food(match.fdc_id) do
      {:ok, food_data} ->
        attrs = build_nutrition_attrs(ingredient, match, food_data)

        case Ingredients.create_nutrition(attrs) do
          {:ok, nutrition} ->
            # Set as primary if it's the first/only source
            unless Ingredients.has_nutrition?(ingredient.id) do
              Ingredients.set_primary_nutrition(nutrition)
            end
            {:ok, nutrition}

          {:error, changeset} ->
            {:error, {:save_failed, changeset.errors}}
        end

      {:error, reason} ->
        {:error, {:fetch_failed, reason}}
    end
  end

  # Build nutrition attributes from USDA data
  defp build_nutrition_attrs(ingredient, match, food_data) do
    nutrients = food_data.nutrients

    %{
      canonical_ingredient_id: ingredient.id,
      source: :usda,
      source_id: to_string(match.fdc_id),
      source_name: "USDA FoodData Central - #{food_data.data_type}",
      source_url: "https://fdc.nal.usda.gov/fdc-app.html#/food-details/#{match.fdc_id}/nutrients",
      # USDA nutrient values are ALWAYS per 100g, regardless of the "serving size"
      # returned by the API. Store 100g as the serving size for correct calculations.
      serving_size_value: 100,
      serving_size_unit: "g",
      # Keep the USDA serving description for reference (e.g., "1 tsp")
      serving_description: food_data.serving_description,
      is_primary: true,

      # Macros
      calories: nutrients[:calories],
      protein_g: nutrients[:protein_g],
      fat_total_g: nutrients[:fat_total_g],
      fat_saturated_g: nutrients[:fat_saturated_g],
      fat_trans_g: nutrients[:fat_trans_g],
      fat_polyunsaturated_g: nutrients[:fat_polyunsaturated_g],
      fat_monounsaturated_g: nutrients[:fat_monounsaturated_g],
      carbohydrates_g: nutrients[:carbohydrates_g],
      fiber_g: nutrients[:fiber_g],
      sugar_g: nutrients[:sugar_g],
      sugar_added_g: nutrients[:sugar_added_g],

      # Minerals
      sodium_mg: nutrients[:sodium_mg],
      potassium_mg: nutrients[:potassium_mg],
      calcium_mg: nutrients[:calcium_mg],
      iron_mg: nutrients[:iron_mg],
      magnesium_mg: nutrients[:magnesium_mg],
      phosphorus_mg: nutrients[:phosphorus_mg],
      zinc_mg: nutrients[:zinc_mg],

      # Vitamins
      vitamin_a_mcg: nutrients[:vitamin_a_mcg],
      vitamin_c_mg: nutrients[:vitamin_c_mg],
      vitamin_d_mcg: nutrients[:vitamin_d_mcg],
      vitamin_e_mg: nutrients[:vitamin_e_mg],
      vitamin_k_mcg: nutrients[:vitamin_k_mcg],
      vitamin_b6_mg: nutrients[:vitamin_b6_mg],
      vitamin_b12_mcg: nutrients[:vitamin_b12_mcg],
      folate_mcg: nutrients[:folate_mcg],
      thiamin_mg: nutrients[:thiamin_mg],
      riboflavin_mg: nutrients[:riboflavin_mg],
      niacin_mg: nutrients[:niacin_mg],

      # Other
      cholesterol_mg: nutrients[:cholesterol_mg],
      water_g: nutrients[:water_g]
    }
  end
end
