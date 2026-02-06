defmodule Controlcopypasta.Nutrition.FatSecretEnrichmentWorker do
  @moduledoc """
  **Deprecated**: Use `Controlcopypasta.Nutrition.NutritionEnrichmentWorker` instead,
  which fetches from FatSecret, USDA, and Open Food Facts in a single pass.

  This module is kept functional for in-flight Oban jobs on the `:fatsecret` queue.

  ---

  Oban worker to fetch FatSecret nutrition data for canonical ingredients.

  Respects API rate limits:
  - Free tier: 5,000 calls/month (~166/day)
  - Configurable daily/hourly limits
  - Delays between requests to avoid bursts

  ## Usage

      # Enqueue all ingredients without FatSecret data
      FatSecretEnrichmentWorker.enqueue_all()

      # Enqueue a specific ingredient
      FatSecretEnrichmentWorker.enqueue(canonical_ingredient_id)

      # Check progress
      FatSecretEnrichmentWorker.progress()
  """

  use Oban.Worker,
    queue: :fatsecret,
    max_attempts: 3,
    unique: [period: :infinity, keys: [:canonical_ingredient_id]]

  require Logger

  alias Controlcopypasta.{Repo, Ingredients}
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, IngredientNutrition}
  alias Controlcopypasta.Nutrition.FatSecretClient

  import Ecto.Query

  # Default rate limits (conservative for free tier)
  @default_max_per_hour 150
  @default_max_per_day 4000
  @default_delay_ms 3000

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"canonical_ingredient_id" => ingredient_id}}) do
    # Check rate limits
    if rate_limit_exceeded?() do
      Logger.info("FatSecret rate limit exceeded, pausing queue")
      Oban.pause_queue(queue: :fatsecret)
      {:snooze, 3600}  # Retry in 1 hour
    else
      apply_delay()
      fetch_and_save(ingredient_id)
    end
  end

  @doc """
  Enqueue all canonical ingredients that don't have FatSecret nutrition data.
  Prioritizes ingredients by usage_count (most used first).
  """
  def enqueue_all do
    # Get IDs of ingredients that already have FatSecret data
    existing_ids =
      from(n in IngredientNutrition,
        where: n.source == :fatsecret,
        select: n.canonical_ingredient_id
      )
      |> Repo.all()

    # Get all canonical ingredients without FatSecret data, ordered by usage
    ingredients =
      from(c in CanonicalIngredient,
        where: c.id not in ^existing_ids,
        order_by: [desc: coalesce(c.usage_count, 0)],
        select: c.id
      )
      |> Repo.all()

    Logger.info("Enqueueing #{length(ingredients)} ingredients for FatSecret enrichment (ordered by usage)")

    # Enqueue each with a small scheduled delay to spread out initial burst
    # Higher priority (lower number) for more-used ingredients
    ingredients
    |> Enum.with_index()
    |> Enum.each(fn {id, index} ->
      # Stagger jobs by 2 seconds each to avoid initial burst
      scheduled_at = DateTime.add(DateTime.utc_now(), index * 2, :second)
      # Priority 0-3 based on position (most used get priority 0)
      priority = min(3, div(index, 100))

      %{canonical_ingredient_id: id}
      |> new(scheduled_at: scheduled_at, priority: priority)
      |> Oban.insert()
    end)

    {:ok, length(ingredients)}
  end

  @doc """
  Enqueue a single ingredient for FatSecret enrichment.
  """
  def enqueue(canonical_ingredient_id) do
    %{canonical_ingredient_id: canonical_ingredient_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Get progress stats for the enrichment process.
  """
  def progress do
    total = Repo.aggregate(CanonicalIngredient, :count)

    with_fatsecret =
      from(n in IngredientNutrition,
        where: n.source == :fatsecret,
        select: count(fragment("DISTINCT ?", n.canonical_ingredient_id))
      )
      |> Repo.one()

    pending =
      Oban.Job
      |> where([j], j.queue == "fatsecret")
      |> where([j], j.state in ["available", "scheduled", "retryable"])
      |> Repo.aggregate(:count)

    completed_today = count_completed_since(hours: 24)
    completed_hour = count_completed_since(hours: 1)

    %{
      total_ingredients: total,
      with_fatsecret_data: with_fatsecret,
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
    Oban.resume_queue(queue: :fatsecret)
  end

  # Private functions

  defp fetch_and_save(ingredient_id) do
    ingredient = Repo.get(CanonicalIngredient, ingredient_id)

    if ingredient do
      search_term = ingredient.name

      Logger.info("Fetching FatSecret data for: #{search_term}")

      case FatSecretClient.search_and_get_nutrition(search_term) do
        {:ok, food_data} ->
          save_nutrition(ingredient, food_data)

        {:error, :not_found} ->
          Logger.info("No FatSecret match for: #{search_term}")
          # Try with display_name if different
          if ingredient.display_name && ingredient.display_name != ingredient.name do
            case FatSecretClient.search_and_get_nutrition(ingredient.display_name) do
              {:ok, food_data} -> save_nutrition(ingredient, food_data)
              {:error, _} -> {:ok, :no_match}
            end
          else
            {:ok, :no_match}
          end

        {:error, :rate_limited} ->
          Logger.warning("FatSecret API rate limited")
          Oban.pause_queue(queue: :fatsecret)
          {:snooze, 3600}

        {:error, :missing_credentials} ->
          Logger.error("FatSecret credentials not configured")
          {:cancel, :missing_credentials}

        {:error, reason} ->
          Logger.error("FatSecret fetch failed for #{search_term}: #{inspect(reason)}")
          {:error, reason}
      end
    else
      Logger.warning("Ingredient not found: #{ingredient_id}")
      {:ok, :ingredient_not_found}
    end
  end

  defp save_nutrition(ingredient, food_data) do
    nutrients = food_data.nutrients

    # Demote any existing primary sources for this ingredient
    demote_existing_primary(ingredient.id)

    attrs = %{
      canonical_ingredient_id: ingredient.id,
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
      is_primary: true,  # FatSecret is now the preferred source
      retrieved_at: DateTime.utc_now()
    }

    case Ingredients.create_nutrition(attrs) do
      {:ok, nutrition} ->
        Logger.info("Saved FatSecret nutrition for #{ingredient.name}: #{nutrition.id}")
        {:ok, nutrition}

      {:error, changeset} ->
        Logger.error("Failed to save FatSecret nutrition for #{ingredient.name}: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  # Demote any existing primary nutrition sources for this ingredient
  defp demote_existing_primary(canonical_ingredient_id) do
    from(n in IngredientNutrition,
      where: n.canonical_ingredient_id == ^canonical_ingredient_id and n.is_primary == true
    )
    |> Repo.update_all(set: [is_primary: false])
  end

  # Normalize serving size to per 100g for consistency
  defp normalize_serving_size(food_data) do
    case {food_data.serving_size_value, food_data.serving_size_unit} do
      {value, "g"} when is_number(value) -> Decimal.new("#{value}")
      _ -> Decimal.new("100")  # Default to 100g if unclear
    end
  end

  defp to_decimal(nil), do: nil
  defp to_decimal(value) when is_number(value), do: Decimal.from_float(value * 1.0)
  defp to_decimal(value), do: Decimal.new("#{value}")

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
    |> where([j], j.queue == "fatsecret")
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
    Application.get_env(:controlcopypasta, :fatsecret, [])
    |> Keyword.get(key, default)
  end
end
