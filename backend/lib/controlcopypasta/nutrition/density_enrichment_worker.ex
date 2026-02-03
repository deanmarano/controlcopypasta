defmodule Controlcopypasta.Nutrition.DensityEnrichmentWorker do
  @moduledoc """
  Oban worker to fetch density data for canonical ingredients from multiple APIs.

  Tries sources in order: FatSecret (best serving data), USDA (authoritative),
  then Open Food Facts (good for branded/international products).
  Deduplicates results by (volume_unit, preparation), keeping highest confidence.

  ## Usage

      # Enqueue all ingredients without density data
      DensityEnrichmentWorker.enqueue_all()

      # Enqueue a specific ingredient
      DensityEnrichmentWorker.enqueue(canonical_ingredient_id)

      # Check progress
      DensityEnrichmentWorker.progress()

  ## Rate Limits

  Open Food Facts has the most restrictive rate limit (10 searches/min),
  so we space requests 6+ seconds apart to stay well under all limits.
  """

  use Oban.Worker,
    queue: :density,
    max_attempts: 3,
    unique: [period: :infinity, keys: [:canonical_ingredient_id]]

  require Logger

  alias Controlcopypasta.{Repo, Ingredients}
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, IngredientDensity}
  alias Controlcopypasta.Nutrition.{FatSecretClient, USDAClient, OpenFoodFactsClient, SearchQueryPreprocessor}

  import Ecto.Query

  # Default rate limits (conservative, respecting Open Food Facts 10/min limit)
  @default_max_per_hour 150
  @default_max_per_day 4000
  # 6 seconds between requests to stay under Open Food Facts 10/min limit
  @default_delay_ms 6000

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"canonical_ingredient_id" => ingredient_id}}) do
    # Check rate limits
    if rate_limit_exceeded?() do
      Logger.info("Density enrichment rate limit exceeded, pausing queue")
      Oban.pause_queue(queue: :density)
      {:snooze, 3600}  # Retry in 1 hour
    else
      apply_delay()
      fetch_and_save_densities(ingredient_id)
    end
  end

  @doc """
  Enqueue all canonical ingredients that don't have density data.
  Prioritizes ingredients by usage_count (most used first).
  """
  def enqueue_all do
    ingredients = list_ingredients_without_density()

    Logger.info("Enqueueing #{length(ingredients)} ingredients for density enrichment (ordered by usage)")

    # Enqueue each with a small scheduled delay to spread out initial burst
    ingredients
    |> Enum.with_index()
    |> Enum.each(fn {ingredient, index} ->
      # Stagger jobs by 2 seconds each to avoid initial burst
      scheduled_at = DateTime.add(DateTime.utc_now(), index * 2, :second)
      # Priority 0-3 based on position (most used get priority 0)
      priority = min(3, div(index, 100))

      %{canonical_ingredient_id: ingredient.id}
      |> new(scheduled_at: scheduled_at, priority: priority)
      |> Oban.insert()
    end)

    {:ok, length(ingredients)}
  end

  @doc """
  Enqueue a single ingredient for density enrichment.
  """
  def enqueue(canonical_ingredient_id) do
    %{canonical_ingredient_id: canonical_ingredient_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Get progress stats for the density enrichment process.
  """
  def progress do
    total = Repo.aggregate(CanonicalIngredient, :count)

    with_density =
      from(d in IngredientDensity,
        select: count(fragment("DISTINCT ?", d.canonical_ingredient_id))
      )
      |> Repo.one()

    pending =
      Oban.Job
      |> where([j], j.queue == "density")
      |> where([j], j.state in ["available", "scheduled", "retryable"])
      |> Repo.aggregate(:count)

    completed_today = count_completed_since(hours: 24)
    completed_hour = count_completed_since(hours: 1)

    %{
      total_ingredients: total,
      with_density_data: with_density,
      without_density_data: total - with_density,
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
    Oban.resume_queue(queue: :density)
  end

  # Private functions

  defp fetch_and_save_densities(ingredient_id) do
    ingredient = Repo.get(CanonicalIngredient, ingredient_id)

    if ingredient do
      # Skip if ingredient appears to be equipment rather than food
      if SearchQueryPreprocessor.equipment?(ingredient.name) do
        Logger.info("Skipping equipment: #{ingredient.name}")
        {:ok, :equipment_skipped}
      else
        # Generate search variations using preprocessor
        variations = SearchQueryPreprocessor.search_variations(ingredient.name, ingredient.display_name)
        Logger.info("Fetching density data for: #{ingredient.name}, variations: #{inspect(variations)}")

        # Try each API with variations
        fatsecret_densities = try_fatsecret_with_variations(ingredient, variations)
        usda_densities = try_usda_with_variations(ingredient, variations)
        off_densities = try_open_food_facts_with_variations(ingredient, variations)

        # Combine and deduplicate by (unit, preparation), keeping highest confidence
        all_densities =
          (fatsecret_densities ++ usda_densities ++ off_densities)
          |> deduplicate_by_unit()

        if Enum.empty?(all_densities) do
          Logger.info("No density data found for: #{ingredient.name}")
          {:ok, :no_data}
        else
          # Save all unique densities
          saved_count =
            Enum.reduce(all_densities, 0, fn density_attrs, count ->
              case Ingredients.upsert_density(density_attrs) do
                {:ok, _} -> count + 1
                {:error, reason} ->
                  Logger.warning("Failed to save density for #{ingredient.name}: #{inspect(reason)}")
                  count
              end
            end)

          Logger.info("Saved #{saved_count} densities for #{ingredient.name}")
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
      # Try each variation until we get results
      Enum.reduce_while(variations, [], fn query, _acc ->
        case search_and_get_fatsecret(query, ingredient.id) do
          densities when is_list(densities) and length(densities) > 0 ->
            Logger.debug("FatSecret returned #{length(densities)} densities for query: #{query}")
            {:halt, densities}

          _ ->
            {:cont, []}
        end
      end)
    else
      []
    end
  end

  defp search_and_get_fatsecret(query, ingredient_id) do
    case FatSecretClient.search(query, max_results: 5) do
      {:ok, [_ | _] = results} ->
        # Use string similarity to find best match
        alias Controlcopypasta.Nutrition.StringSimilarity

        scored =
          results
          |> Enum.map(fn r -> {r, StringSimilarity.match_score(query, r.food_name || "")} end)
          |> Enum.filter(fn {_, score} -> score >= 0.4 end)
          |> Enum.sort_by(fn {_, score} -> -score end)

        case scored do
          [{best, _} | _] ->
            case FatSecretClient.get_food_with_raw(best.food_id) do
              {:ok, %{raw: raw_food}} ->
                FatSecretClient.extract_densities_from_raw(raw_food, ingredient_id)
              _ -> []
            end
          [] -> []
        end

      {:error, reason} ->
        Logger.debug("FatSecret search failed for #{query}: #{inspect(reason)}")
        []

      _ -> []
    end
  end

  # Try USDA with each search variation, using fallback to Branded data
  defp try_usda_with_variations(ingredient, variations) do
    if USDAClient.api_key_configured?() do
      Enum.reduce_while(variations, [], fn query, _acc ->
        case search_and_get_usda(query, ingredient.id) do
          densities when is_list(densities) and length(densities) > 0 ->
            Logger.debug("USDA returned #{length(densities)} densities for query: #{query}")
            {:halt, densities}

          _ ->
            {:cont, []}
        end
      end)
    else
      []
    end
  end

  defp search_and_get_usda(query, ingredient_id) do
    alias Controlcopypasta.Nutrition.StringSimilarity

    # Use search_with_fallback to try Foundation/SR Legacy first, then Branded
    case USDAClient.search_with_fallback(query, page_size: 5) do
      {:ok, [_ | _] = results} ->
        # Score results by similarity
        scored =
          results
          |> Enum.map(fn r ->
            score = StringSimilarity.match_score(query, r.description)
            # Bonus for Foundation/SR Legacy
            type_bonus = case r.data_type do
              "Foundation" -> 0.1
              "SR Legacy" -> 0.05
              _ -> 0
            end
            {r, score + type_bonus}
          end)
          |> Enum.filter(fn {_, score} -> score >= 0.4 end)
          |> Enum.sort_by(fn {_, score} -> -score end)

        case scored do
          [{best, _} | _] ->
            case USDAClient.get_food_with_raw(best.fdc_id) do
              {:ok, %{raw: raw_food}} ->
                USDAClient.extract_densities_from_raw(raw_food, ingredient_id)
              _ -> []
            end
          [] -> []
        end

      {:error, reason} ->
        Logger.debug("USDA search failed for #{query}: #{inspect(reason)}")
        []

      _ -> []
    end
  end

  # Try Open Food Facts with each search variation
  defp try_open_food_facts_with_variations(ingredient, variations) do
    Enum.reduce_while(variations, [], fn query, _acc ->
      case search_and_get_off(query, ingredient.id) do
        densities when is_list(densities) and length(densities) > 0 ->
          Logger.debug("Open Food Facts returned #{length(densities)} densities for query: #{query}")
          {:halt, densities}

        _ ->
          {:cont, []}
      end
    end)
  end

  defp search_and_get_off(query, ingredient_id) do
    case OpenFoodFactsClient.search_and_get_first(query) do
      {:ok, %{raw: raw_product}} ->
        OpenFoodFactsClient.extract_densities_from_raw(raw_product, ingredient_id)

      {:error, :rate_limited} ->
        Logger.warning("Open Food Facts rate limited for #{query}")
        []

      {:error, reason} ->
        Logger.debug("Open Food Facts search failed for #{query}: #{inspect(reason)}")
        []
    end
  end

  # Deduplicate densities by (unit, preparation, source), keeping highest confidence within each source
  # This allows storing data from multiple sources for the same unit/preparation
  defp deduplicate_by_unit(densities) do
    densities
    |> Enum.group_by(fn d -> {d.volume_unit, d.preparation, d.source} end)
    |> Enum.map(fn {_key, group} ->
      # Keep the one with highest confidence within same source
      Enum.max_by(group, fn d ->
        case d.confidence do
          %Decimal{} = dec -> Decimal.to_float(dec)
          val when is_number(val) -> val
          _ -> 0
        end
      end)
    end)
  end

  defp list_ingredients_without_density do
    subquery = from(d in IngredientDensity, select: d.canonical_ingredient_id)

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
    |> where([j], j.queue == "density")
    |> where([j], j.state == "completed")
    |> where([j], j.completed_at >= ^since)
    |> Repo.aggregate(:count)
  end

  defp apply_delay do
    delay = get_config(:delay_ms, @default_delay_ms)
    # Add some randomness to avoid patterns
    jitter = :rand.uniform(1000)
    Process.sleep(delay + jitter)
  end

  defp get_config(key, default) do
    Application.get_env(:controlcopypasta, :density, [])
    |> Keyword.get(key, default)
  end
end
