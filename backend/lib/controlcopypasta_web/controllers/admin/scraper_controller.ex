defmodule ControlcopypastaWeb.Admin.ScraperController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Scraper
  alias Controlcopypasta.Browser.Pool, as: BrowserPool
  alias Controlcopypasta.Workers.IngredientParser
  alias Controlcopypasta.Nutrition.FatSecretEnrichmentWorker
  alias Controlcopypasta.Nutrition.DensityEnrichmentWorker
  alias Controlcopypasta.Repo
  import Ecto.Query

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Lists all domains with their scrape statistics.
  """
  def domains(conn, _params) do
    stats = Scraper.get_domain_stats()
    json(conn, %{data: stats})
  end

  @doc """
  Adds a new domain with seed URLs.

  Body:
  {
    "domain": "example.com",
    "seed_urls": ["https://example.com/recipes"]
  }
  """
  def add_domain(conn, %{"domain" => domain, "seed_urls" => seed_urls}) do
    {:ok, result} = Scraper.enqueue_domain(domain, seed_urls)

    conn
    |> put_status(:created)
    |> json(%{
      data: %{
        domain: result.domain,
        enqueued: result.enqueued,
        errors: result.errors
      }
    })
  end

  @doc """
  Gets overall queue statistics.
  """
  def queue_stats(conn, _params) do
    stats = Scraper.get_scrape_stats()
    json(conn, %{data: stats})
  end

  @doc """
  Gets rate limit status.
  """
  def rate_limits(conn, _params) do
    status = Scraper.get_rate_limit_status()
    json(conn, %{data: status})
  end

  @doc """
  Pauses all scraping.
  """
  def pause(conn, _params) do
    {:ok, result} = Scraper.pause_scraping()
    json(conn, %{data: result})
  end

  @doc """
  Resumes scraping.
  """
  def resume(conn, params) do
    limit = Map.get(params, "limit", 100)
    {:ok, result} = Scraper.resume_scraping(limit: limit)
    json(conn, %{data: result})
  end

  @doc """
  Lists failed URLs for a domain.
  """
  def failed(conn, params) do
    opts = []
    opts = if params["domain"], do: [{:domain, params["domain"]} | opts], else: opts
    opts = if params["limit"], do: [{:limit, String.to_integer(params["limit"])} | opts], else: opts

    failed = Scraper.list_failed(opts)

    json(conn, %{
      data: Enum.map(failed, fn url ->
        %{
          id: url.id,
          url: url.url,
          domain: url.domain,
          error: url.error,
          attempts: url.attempts,
          updated_at: url.updated_at
        }
      end)
    })
  end

  @doc """
  Retries failed URLs.
  """
  def retry_failed(conn, params) do
    opts = if params["domain"], do: [domain: params["domain"]], else: []
    {:ok, result} = Scraper.retry_failed(opts)
    json(conn, %{data: result})
  end

  @doc """
  Gets browser pool status.
  """
  def browser_status(conn, _params) do
    status = BrowserPool.status()
    json(conn, %{data: status})
  end

  @doc """
  Gets currently executing scraper workers and their URLs.
  """
  def executing_workers(conn, _params) do
    workers =
      from(j in "oban_jobs",
        where: j.state == "executing" and j.queue == "scraper",
        select: %{
          id: j.id,
          args: j.args,
          attempted_at: j.attempted_at
        },
        order_by: [asc: j.attempted_at]
      )
      |> Repo.all()
      |> Enum.map(fn job ->
        %{
          id: job.id,
          url: get_in(job.args, ["url"]),
          started_at: job.attempted_at
        }
      end)

    json(conn, %{data: workers})
  end

  @doc """
  Captures a screenshot of a domain's homepage.
  """
  def capture_screenshot(conn, %{"domain" => domain}) do
    url = "https://#{domain}"

    case BrowserPool.screenshot(url, timeout: 60_000) do
      {:ok, base64_screenshot} ->
        screenshot = Base.decode64!(base64_screenshot)
        {:ok, _domain} = Scraper.update_domain_screenshot(domain, screenshot)
        json(conn, %{data: %{domain: domain, status: "captured"}})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to capture screenshot: #{inspect(reason)}"})
    end
  end

  @doc """
  Resets stale processing URLs back to pending.

  URLs stuck in "processing" for longer than threshold are reset.
  """
  def reset_stale(conn, params) do
    threshold = Map.get(params, "threshold_minutes", 60)
    {:ok, result} = Scraper.reset_stale_processing(threshold_minutes: threshold)
    json(conn, %{data: result})
  end

  @doc """
  Triggers ingredient parsing for recipes.

  Body:
  - `{"domain": "cooking.nytimes.com"}` - Parse all recipes for a domain
  - `{"force": true}` - Force reparse ALL recipes (regenerate pre_steps, alternatives, etc.)
  - `{"domain": "...", "force": true}` - Force reparse all recipes for a domain
  - `{}` - Parse all unparsed recipes
  """
  def parse_ingredients(conn, params) do
    force = Map.get(params, "force", false)

    job_args =
      case params do
        %{"domain" => domain} -> %{"domain" => domain, "force" => force}
        _ -> %{"force" => force}
      end

    case Oban.insert(IngredientParser.new(job_args)) do
      {:ok, _job} ->
        json(conn, %{data: %{status: "started", params: job_args}})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to start parsing: #{inspect(reason)}"})
    end
  end

  @doc """
  Gets ingredient enrichment stats (nutrition and density progress).
  """
  def ingredient_enrichment_stats(conn, _params) do
    nutrition_stats = FatSecretEnrichmentWorker.progress()
    density_stats = DensityEnrichmentWorker.progress()

    json(conn, %{
      data: %{
        nutrition: nutrition_stats,
        density: density_stats
      }
    })
  end

  @doc """
  Triggers nutrition enrichment for all ingredients without FatSecret data.
  """
  def enqueue_nutrition_enrichment(conn, _params) do
    case FatSecretEnrichmentWorker.enqueue_all() do
      {:ok, count} ->
        json(conn, %{data: %{status: "started", enqueued: count}})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to start nutrition enrichment: #{inspect(reason)}"})
    end
  end

  @doc """
  Triggers density enrichment for all ingredients without density data.
  """
  def enqueue_density_enrichment(conn, _params) do
    case DensityEnrichmentWorker.enqueue_all() do
      {:ok, count} ->
        json(conn, %{data: %{status: "started", enqueued: count}})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to start density enrichment: #{inspect(reason)}"})
    end
  end

  @doc """
  Resumes the FatSecret enrichment queue if paused.
  """
  def resume_nutrition_enrichment(conn, _params) do
    FatSecretEnrichmentWorker.resume()
    json(conn, %{data: %{status: "resumed"}})
  end

  @doc """
  Resumes the density enrichment queue if paused.
  """
  def resume_density_enrichment(conn, _params) do
    DensityEnrichmentWorker.resume()
    json(conn, %{data: %{status: "resumed"}})
  end

  @doc """
  Gets ingredient parsing progress stats.
  """
  def parsing_stats(conn, _params) do
    alias Controlcopypasta.Recipes.Recipe

    # Get total and parsed recipe counts
    total_recipes = Repo.aggregate(Recipe, :count)
    parsed_recipes = from(r in Recipe, where: not is_nil(r.ingredients_parsed_at))
                     |> Repo.aggregate(:count)

    # Get active parsing jobs
    active_jobs = from(j in "oban_jobs",
      where: j.worker == "Controlcopypasta.Workers.IngredientParser" and j.state in ["executing", "available", "scheduled"],
      select: %{
        id: j.id,
        state: j.state,
        args: j.args,
        inserted_at: j.inserted_at,
        scheduled_at: j.scheduled_at
      },
      order_by: [desc: j.inserted_at],
      limit: 5
    ) |> Repo.all()

    # Get last completed job
    last_completed = from(j in "oban_jobs",
      where: j.worker == "Controlcopypasta.Workers.IngredientParser" and j.state == "completed",
      select: %{completed_at: j.completed_at, args: j.args},
      order_by: [desc: j.completed_at],
      limit: 1
    ) |> Repo.one()

    json(conn, %{
      data: %{
        total_recipes: total_recipes,
        parsed_recipes: parsed_recipes,
        unparsed_recipes: total_recipes - parsed_recipes,
        percent_complete: if(total_recipes > 0, do: Float.round(parsed_recipes / total_recipes * 100, 1), else: 0),
        active_jobs: Enum.map(active_jobs, fn job ->
          %{
            id: job.id,
            state: job.state,
            offset: get_in(job.args, ["offset"]) || 0,
            force: get_in(job.args, ["force"]) || false,
            inserted_at: job.inserted_at
          }
        end),
        last_completed: if(last_completed, do: %{
          completed_at: last_completed.completed_at,
          offset: get_in(last_completed.args, ["offset"]) || 0
        }, else: nil)
      }
    })
  end
end
