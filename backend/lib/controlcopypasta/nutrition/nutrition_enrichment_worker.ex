defmodule Controlcopypasta.Nutrition.NutritionEnrichmentWorker do
  @moduledoc """
  Oban worker to fetch nutrition data for canonical ingredients from multiple APIs.

  Tries sources in order: FatSecret (good branded data), USDA (authoritative),
  then Open Food Facts (good for international products).
  Stores all successful results, deduplicating by (source, source_id).

  Replaces `FatSecretEnrichmentWorker` for new enrichment runs.

  ## Usage

      # Enqueue ingredients without any nutrition data
      NutritionEnrichmentWorker.enqueue_all()

      # Enqueue ALL ingredients for multi-source backfill
      NutritionEnrichmentWorker.enqueue_all_sources()

      # Enqueue a specific ingredient
      NutritionEnrichmentWorker.enqueue(canonical_ingredient_id)

      # Refetch ALL ingredients (delete old data, fetch fresh)
      NutritionEnrichmentWorker.enqueue_refetch_all()

      # Refetch a specific ingredient
      NutritionEnrichmentWorker.enqueue_refetch(canonical_ingredient_id)

      # Check progress
      NutritionEnrichmentWorker.progress()

  ## Rate Limits

  Open Food Facts has the most restrictive rate limit (10 searches/min),
  so we space requests 6+ seconds apart to stay well under all limits.
  """

  use Oban.Worker,
    queue: :nutrition,
    max_attempts: 3,
    unique: [period: :infinity, keys: [:canonical_ingredient_id]]

  require Logger

  alias Controlcopypasta.{Repo, Ingredients}
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, IngredientNutrition}
  alias Controlcopypasta.Nutrition.{FatSecretClient, USDAClient, OpenFoodFactsClient, SearchQueryPreprocessor}

  import Ecto.Query

  # Default rate limits (conservative, respecting Open Food Facts 10/min limit)
  @default_max_per_hour 150
  @default_max_per_day 4000
  # 6 seconds between requests to stay under Open Food Facts 10/min limit
  @default_delay_ms 6000

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"canonical_ingredient_id" => ingredient_id} = args}) do
    if rate_limit_exceeded?() do
      Logger.info("Nutrition enrichment rate limit exceeded, pausing queue")
      Oban.pause_queue(queue: :nutrition)
      {:snooze, 3600}
    else
      apply_delay()

      # If refetch mode, delete existing nutrition data first
      if args["refetch"] do
        delete_existing_nutrition(ingredient_id)
      end

      fetch_and_save_nutrition(ingredient_id)
    end
  end

  @doc """
  Enqueue all canonical ingredients that don't have any nutrition data.
  Prioritizes ingredients by usage_count (most used first).
  """
  def enqueue_all do
    ingredients = list_ingredients_without_nutrition()

    Logger.info("Enqueueing #{length(ingredients)} ingredients for nutrition enrichment (ordered by usage)")

    enqueue_list(ingredients)
  end

  @doc """
  Re-enqueue ALL canonical ingredients to fetch nutrition data from all sources.
  Use this to backfill data from USDA and Open Food Facts for ingredients
  that only have FatSecret data.
  """
  def enqueue_all_sources do
    ingredients =
      from(ci in CanonicalIngredient,
        order_by: [desc: coalesce(ci.usage_count, 0)],
        select: ci
      )
      |> Repo.all()

    Logger.info("Enqueueing #{length(ingredients)} ingredients for multi-source nutrition enrichment")

    enqueue_list(ingredients)
  end

  defp enqueue_list(ingredients, opts \\ []) do
    refetch = Keyword.get(opts, :refetch, false)

    ingredients
    |> Enum.with_index()
    |> Enum.each(fn {ingredient, index} ->
      scheduled_at = DateTime.add(DateTime.utc_now(), index * 2, :second)
      priority = min(3, div(index, 100))

      args = %{canonical_ingredient_id: ingredient.id}
      args = if refetch, do: Map.put(args, :refetch, true), else: args

      # Use replace for refetch to override existing completed/discarded jobs
      job_opts = [scheduled_at: scheduled_at, priority: priority]
      job_opts = if refetch, do: Keyword.put(job_opts, :replace, [:args, :scheduled_at, :state]), else: job_opts

      args
      |> new(job_opts)
      |> Oban.insert()
    end)

    {:ok, length(ingredients)}
  end

  @doc """
  Enqueue a single ingredient for nutrition enrichment.
  """
  def enqueue(canonical_ingredient_id) do
    %{canonical_ingredient_id: canonical_ingredient_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Refetch ALL ingredients - deletes existing nutrition data and fetches fresh.
  Use this after improving the matching algorithm to get better matches.
  Prioritizes by usage_count (most used first).
  """
  def enqueue_refetch_all do
    ingredients =
      from(ci in CanonicalIngredient,
        order_by: [desc: coalesce(ci.usage_count, 0)],
        select: ci
      )
      |> Repo.all()

    Logger.info("Enqueueing #{length(ingredients)} ingredients for nutrition REFETCH (delete + fetch)")

    enqueue_list(ingredients, refetch: true)
  end

  @doc """
  Refetch a single ingredient - deletes existing nutrition and fetches fresh.
  """
  def enqueue_refetch(canonical_ingredient_id) do
    %{canonical_ingredient_id: canonical_ingredient_id, refetch: true}
    |> new(replace: [:args, :scheduled_at])
    |> Oban.insert()
  end

  @doc """
  Get progress stats for the nutrition enrichment process.
  Includes per-source breakdown.
  """
  def progress do
    total = Repo.aggregate(CanonicalIngredient, :count)

    with_nutrition =
      from(n in IngredientNutrition,
        select: count(fragment("DISTINCT ?", n.canonical_ingredient_id))
      )
      |> Repo.one()

    by_source =
      from(n in IngredientNutrition,
        group_by: n.source,
        select: {n.source, count(fragment("DISTINCT ?", n.canonical_ingredient_id))}
      )
      |> Repo.all()
      |> Map.new(fn {source, count} -> {Atom.to_string(source), count} end)

    pending =
      Oban.Job
      |> where([j], j.queue == "nutrition")
      |> where([j], j.state in ["available", "scheduled", "retryable"])
      |> Repo.aggregate(:count)

    completed_today = count_completed_since(hours: 24)
    completed_hour = count_completed_since(hours: 1)

    %{
      total_ingredients: total,
      with_nutrition_data: with_nutrition,
      without_nutrition_data: total - with_nutrition,
      by_source: by_source,
      pending_jobs: pending,
      completed_today: completed_today,
      completed_this_hour: completed_hour,
      daily_limit: get_config(:max_per_day, @default_max_per_day),
      hourly_limit: get_config(:max_per_hour, @default_max_per_hour)
    }
  end

  @doc """
  Resume the queue if it was paused due to rate limits.
  """
  def resume do
    Oban.resume_queue(queue: :nutrition)
  end

  # Private functions

  defp fetch_and_save_nutrition(ingredient_id) do
    ingredient = Repo.get(CanonicalIngredient, ingredient_id)

    if ingredient do
      if SearchQueryPreprocessor.equipment?(ingredient.name) do
        Logger.info("Skipping equipment: #{ingredient.name}")
        {:ok, :equipment_skipped}
      else
        variations = SearchQueryPreprocessor.search_variations(ingredient.name, ingredient.display_name)
        Logger.info("Fetching nutrition data for: #{ingredient.name}, variations: #{inspect(variations)}")

        # Try each API with variations - collect all results
        fatsecret_results = try_fatsecret_with_variations(ingredient, variations)
        usda_results = try_usda_with_variations(ingredient, variations)
        off_results = try_open_food_facts_with_variations(ingredient, variations)

        all_results = fatsecret_results ++ usda_results ++ off_results

        if Enum.empty?(all_results) do
          Logger.info("No nutrition data found for: #{ingredient.name}")
          {:ok, :no_data}
        else
          saved_count =
            Enum.reduce(all_results, 0, fn attrs, count ->
              case Ingredients.upsert_nutrition(attrs) do
                {:ok, _} -> count + 1
                {:error, reason} ->
                  Logger.warning("Failed to save nutrition for #{ingredient.name}: #{inspect(reason)}")
                  count
              end
            end)

          Logger.info("Saved #{saved_count} nutrition records for #{ingredient.name}")
          {:ok, %{saved: saved_count}}
        end
      end
    else
      Logger.warning("Ingredient not found: #{ingredient_id}")
      {:ok, :ingredient_not_found}
    end
  end

  # Try FatSecret with each search variation until results found
  defp try_fatsecret_with_variations(ingredient, variations) do
    if FatSecretClient.credentials_configured?() do
      Enum.reduce_while(variations, [], fn query, _acc ->
        case FatSecretClient.search_and_get_nutrition(query) do
          {:ok, food_data} ->
            attrs = build_fatsecret_attrs(food_data, ingredient.id)
            {:halt, [attrs]}

          {:error, :rate_limited} ->
            Logger.warning("FatSecret rate limited")
            {:halt, []}

          {:error, _} ->
            {:cont, []}
        end
      end)
    else
      []
    end
  end

  defp build_fatsecret_attrs(food_data, canonical_ingredient_id) do
    nutrients = food_data.nutrients

    %{
      canonical_ingredient_id: canonical_ingredient_id,
      source: :fatsecret,
      source_id: food_data.food_id,
      source_name: food_data.food_name,
      source_url: food_data.food_url,
      serving_size_value: normalize_serving_size(food_data),
      serving_size_unit: "g",
      serving_description: food_data.serving_description,
      calories: to_decimal(nutrients[:calories]),
      protein_g: to_decimal(nutrients[:protein_g]),
      fat_total_g: to_decimal(nutrients[:fat_total_g]),
      fat_saturated_g: to_decimal(nutrients[:fat_saturated_g]),
      fat_trans_g: to_decimal(nutrients[:fat_trans_g]),
      fat_polyunsaturated_g: to_decimal(nutrients[:fat_polyunsaturated_g]),
      fat_monounsaturated_g: to_decimal(nutrients[:fat_monounsaturated_g]),
      carbohydrates_g: to_decimal(nutrients[:carbohydrates_g]),
      fiber_g: to_decimal(nutrients[:fiber_g]),
      sugar_g: to_decimal(nutrients[:sugar_g]),
      sodium_mg: to_decimal(nutrients[:sodium_mg]),
      potassium_mg: to_decimal(nutrients[:potassium_mg]),
      calcium_mg: to_decimal(nutrients[:calcium_mg]),
      iron_mg: to_decimal(nutrients[:iron_mg]),
      cholesterol_mg: to_decimal(nutrients[:cholesterol_mg]),
      vitamin_a_mcg: to_decimal(nutrients[:vitamin_a_mcg]),
      vitamin_c_mg: to_decimal(nutrients[:vitamin_c_mg]),
      vitamin_d_mcg: to_decimal(nutrients[:vitamin_d_mcg]),
      confidence: Decimal.new("0.80"),
      retrieved_at: DateTime.utc_now()
    }
  end

  defp normalize_serving_size(food_data) do
    case {food_data.serving_size_value, food_data.serving_size_unit} do
      {value, "g"} when is_number(value) -> Decimal.new("#{value}")
      _ -> Decimal.new("100")
    end
  end

  # Try USDA with each search variation
  defp try_usda_with_variations(ingredient, variations) do
    if USDAClient.api_key_configured?() do
      Enum.reduce_while(variations, [], fn query, _acc ->
        case USDAClient.search_and_get_nutrition(query) do
          {:ok, parsed_food} ->
            attrs = USDAClient.extract_nutrition_from_parsed(parsed_food, ingredient.id)
            {:halt, [attrs]}

          {:error, :rate_limited} ->
            Logger.warning("USDA rate limited")
            {:halt, []}

          {:error, _} ->
            {:cont, []}
        end
      end)
    else
      []
    end
  end

  # Try Open Food Facts with each search variation
  defp try_open_food_facts_with_variations(ingredient, variations) do
    Enum.reduce_while(variations, [], fn query, _acc ->
      case OpenFoodFactsClient.search_and_get_first(query) do
        {:ok, %{raw: raw_product}} ->
          attrs = OpenFoodFactsClient.extract_nutrition_from_raw(raw_product, ingredient.id)
          {:halt, [attrs]}

        {:error, :rate_limited} ->
          Logger.warning("Open Food Facts rate limited")
          {:halt, []}

        {:error, _} ->
          {:cont, []}
      end
    end)
  end

  defp to_decimal(nil), do: nil
  defp to_decimal(value) when is_number(value), do: Decimal.from_float(value * 1.0)
  defp to_decimal(value), do: Decimal.new("#{value}")

  defp delete_existing_nutrition(ingredient_id) do
    {deleted, _} =
      from(n in IngredientNutrition,
        where: n.canonical_ingredient_id == ^ingredient_id
      )
      |> Repo.delete_all()

    if deleted > 0 do
      Logger.info("Deleted #{deleted} existing nutrition records for ingredient #{ingredient_id}")
    end

    deleted
  end

  defp list_ingredients_without_nutrition do
    subquery = from(n in IngredientNutrition, select: n.canonical_ingredient_id)

    from(ci in CanonicalIngredient,
      where: ci.id not in subquery(subquery),
      order_by: [desc: coalesce(ci.usage_count, 0)],
      select: ci
    )
    |> Repo.all()
  end

  defp rate_limit_exceeded? do
    max_per_hour = get_config(:max_per_hour, @default_max_per_hour)
    max_per_day = get_config(:max_per_day, @default_max_per_day)

    cond do
      max_per_hour > 0 && count_completed_since(hours: 1) >= max_per_hour -> true
      max_per_day > 0 && count_completed_since(hours: 24) >= max_per_day -> true
      true -> false
    end
  end

  defp count_completed_since(hours: hours) do
    since = DateTime.utc_now() |> DateTime.add(-hours * 3600, :second)

    Oban.Job
    |> where([j], j.queue == "nutrition")
    |> where([j], j.state == "completed")
    |> where([j], j.completed_at >= ^since)
    |> Repo.aggregate(:count)
  end

  defp apply_delay do
    delay = get_config(:delay_ms, @default_delay_ms)
    jitter = :rand.uniform(1000)
    Process.sleep(delay + jitter)
  end

  defp get_config(key, default) do
    Application.get_env(:controlcopypasta, :nutrition_enrichment, [])
    |> Keyword.get(key, default)
  end
end
