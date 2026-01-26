defmodule Controlcopypasta.Nutrition.DensityEnrichmentWorker do
  @moduledoc """
  Oban worker to fetch density data for canonical ingredients from FatSecret and USDA APIs.

  Tries FatSecret first (more serving options), then USDA as fallback.
  Deduplicates results by (volume_unit, preparation), keeping highest confidence.

  ## Usage

      # Enqueue all ingredients without density data
      DensityEnrichmentWorker.enqueue_all()

      # Enqueue a specific ingredient
      DensityEnrichmentWorker.enqueue(canonical_ingredient_id)

      # Check progress
      DensityEnrichmentWorker.progress()
  """

  use Oban.Worker,
    queue: :density,
    max_attempts: 3,
    unique: [period: :infinity, keys: [:canonical_ingredient_id]]

  require Logger

  alias Controlcopypasta.{Repo, Ingredients}
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, IngredientDensity}
  alias Controlcopypasta.Nutrition.{FatSecretClient, USDAClient}

  import Ecto.Query

  # Default rate limits (conservative, matching FatSecret limits)
  @default_max_per_hour 150
  @default_max_per_day 4000
  @default_delay_ms 3000

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
      Logger.info("Fetching density data for: #{ingredient.name}")

      # Try FatSecret first (more serving options)
      fatsecret_densities = try_fatsecret(ingredient)

      # Then try USDA for additional/fallback data
      usda_densities = try_usda(ingredient)

      # Combine and deduplicate by (unit, preparation), keeping highest confidence
      all_densities = (fatsecret_densities ++ usda_densities) |> deduplicate_by_unit()

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
    else
      Logger.warning("Ingredient not found: #{ingredient_id}")
      {:ok, :ingredient_not_found}
    end
  end

  defp try_fatsecret(ingredient) do
    if FatSecretClient.credentials_configured?() do
      case FatSecretClient.get_food_with_raw(search_fatsecret(ingredient)) do
        {:ok, %{raw: raw_food}} ->
          densities = FatSecretClient.extract_densities_from_raw(raw_food, ingredient.id)
          Logger.debug("FatSecret returned #{length(densities)} densities for #{ingredient.name}")
          densities

        {:error, :not_found} ->
          # Try with display_name if different
          if ingredient.display_name && ingredient.display_name != ingredient.name do
            case search_and_get_fatsecret(ingredient.display_name, ingredient.id) do
              densities when is_list(densities) -> densities
              _ -> []
            end
          else
            []
          end

        {:error, reason} ->
          Logger.warning("FatSecret fetch failed for #{ingredient.name}: #{inspect(reason)}")
          []
      end
    else
      []
    end
  end

  defp search_fatsecret(ingredient) do
    # Search for the food first, then get the first result's ID
    case FatSecretClient.search(ingredient.name, max_results: 1) do
      {:ok, [first | _]} -> first.food_id
      _ -> nil
    end
  end

  defp search_and_get_fatsecret(name, ingredient_id) do
    case FatSecretClient.search(name, max_results: 1) do
      {:ok, [first | _]} ->
        case FatSecretClient.get_food_with_raw(first.food_id) do
          {:ok, %{raw: raw_food}} ->
            FatSecretClient.extract_densities_from_raw(raw_food, ingredient_id)
          _ -> []
        end
      _ -> []
    end
  end

  defp try_usda(ingredient) do
    if USDAClient.api_key_configured?() do
      case USDAClient.search(ingredient.name, page_size: 1) do
        {:ok, [first | _]} ->
          case USDAClient.get_food_with_raw(first.fdc_id) do
            {:ok, %{raw: raw_food}} ->
              densities = USDAClient.extract_densities_from_raw(raw_food, ingredient.id)
              Logger.debug("USDA returned #{length(densities)} densities for #{ingredient.name}")
              densities

            {:error, reason} ->
              Logger.warning("USDA get_food failed for #{ingredient.name}: #{inspect(reason)}")
              []
          end

        {:ok, []} ->
          # Try with display_name if different
          if ingredient.display_name && ingredient.display_name != ingredient.name do
            search_and_get_usda(ingredient.display_name, ingredient.id)
          else
            []
          end

        {:error, reason} ->
          Logger.warning("USDA search failed for #{ingredient.name}: #{inspect(reason)}")
          []
      end
    else
      []
    end
  end

  defp search_and_get_usda(name, ingredient_id) do
    case USDAClient.search(name, page_size: 1) do
      {:ok, [first | _]} ->
        case USDAClient.get_food_with_raw(first.fdc_id) do
          {:ok, %{raw: raw_food}} ->
            USDAClient.extract_densities_from_raw(raw_food, ingredient_id)
          _ -> []
        end
      _ -> []
    end
  end

  # Deduplicate densities by (unit, preparation), keeping highest confidence
  defp deduplicate_by_unit(densities) do
    densities
    |> Enum.group_by(fn d -> {d.volume_unit, d.preparation} end)
    |> Enum.map(fn {_key, group} ->
      # Keep the one with highest confidence
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
