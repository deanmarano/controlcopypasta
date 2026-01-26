defmodule Controlcopypasta.Scraper do
  @moduledoc """
  Context module for managing the URL scrape queue.

  Provides functions to enqueue URLs for scraping, check status,
  and manage the scrape queue.
  """

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Scraper.{ScrapeUrl, ScrapeWorker}

  @doc """
  Enqueues a single URL for scraping.

  Returns {:ok, scrape_url} if the URL was added or already exists,
  or {:error, changeset} if the URL is invalid.
  """
  def enqueue_url(url, opts \\ []) do
    domain = opts[:domain] || extract_domain(url)

    case get_scrape_url_by_url(url) do
      nil ->
        attrs = %{url: url, domain: domain, status: "pending"}

        case create_scrape_url(attrs) do
          {:ok, scrape_url} ->
            # Create Oban job
            %{url: url, scrape_url_id: scrape_url.id}
            |> ScrapeWorker.new()
            |> Oban.insert()

            {:ok, scrape_url}

          error ->
            error
        end

      existing ->
        {:ok, existing}
    end
  end

  @doc """
  Enqueues multiple URLs for scraping.

  Returns a map with :ok and :error counts.
  """
  def enqueue_urls(urls, opts \\ []) do
    results =
      urls
      |> Enum.map(fn url -> enqueue_url(url, opts) end)

    ok_count = Enum.count(results, &match?({:ok, _}, &1))
    error_count = Enum.count(results, &match?({:error, _}, &1))

    %{ok: ok_count, errors: error_count}
  end

  @doc """
  Enqueues a domain for crawling with seed URLs.

  Creates scrape URLs for the seed URLs to bootstrap the crawl.
  """
  def enqueue_domain(domain, seed_urls) when is_list(seed_urls) do
    normalized_domain = normalize_domain(domain)

    results =
      seed_urls
      |> Enum.map(fn url -> enqueue_url(url, domain: normalized_domain) end)

    ok_count = Enum.count(results, &match?({:ok, _}, &1))
    error_count = Enum.count(results, &match?({:error, _}, &1))

    {:ok, %{domain: normalized_domain, enqueued: ok_count, errors: error_count}}
  end

  @doc """
  Gets scrape queue statistics.
  """
  def get_scrape_stats do
    stats =
      ScrapeUrl
      |> group_by([s], s.status)
      |> select([s], %{status: s.status, count: count(s.id)})
      |> Repo.all()
      |> Map.new(fn %{status: status, count: count} -> {status, count} end)

    total = Enum.sum(Map.values(stats))

    Map.merge(
      %{"pending" => 0, "processing" => 0, "completed" => 0, "failed" => 0, "total" => total},
      stats
    )
  end

  @doc """
  Gets scrape stats by domain.
  """
  def get_domain_stats(domain \\ nil) do
    query =
      ScrapeUrl
      |> group_by([s], [s.domain, s.status])
      |> select([s], %{domain: s.domain, status: s.status, count: count(s.id)})

    query = if domain, do: where(query, [s], s.domain == ^domain), else: query

    Repo.all(query)
    |> Enum.group_by(& &1.domain)
    |> Enum.map(fn {domain, stats} ->
      status_counts = Map.new(stats, fn %{status: s, count: c} -> {s, c} end)
      total = Enum.sum(Map.values(status_counts))

      %{
        domain: domain,
        pending: Map.get(status_counts, "pending", 0),
        processing: Map.get(status_counts, "processing", 0),
        completed: Map.get(status_counts, "completed", 0),
        failed: Map.get(status_counts, "failed", 0),
        total: total
      }
    end)
    |> Enum.sort_by(& &1.total, :desc)
  end

  @doc """
  Lists failed scrape URLs.
  """
  def list_failed(opts \\ []) do
    domain = opts[:domain]
    limit = opts[:limit] || 50

    query =
      ScrapeUrl
      |> where([s], s.status == "failed")
      |> order_by([s], desc: s.updated_at)
      |> limit(^limit)

    query = if domain, do: where(query, [s], s.domain == ^domain), else: query

    Repo.all(query)
  end

  @doc """
  Retries failed scrape URLs.

  Resets status to pending and creates new Oban jobs.
  """
  def retry_failed(opts \\ []) do
    domain = opts[:domain]

    query =
      ScrapeUrl
      |> where([s], s.status == "failed")

    query = if domain, do: where(query, [s], s.domain == ^domain), else: query

    failed_urls = Repo.all(query)

    results =
      failed_urls
      |> Enum.map(fn scrape_url ->
        with {:ok, updated} <- update_scrape_url(scrape_url, %{status: "pending", error: nil}) do
          %{url: updated.url, scrape_url_id: updated.id}
          |> ScrapeWorker.new()
          |> Oban.insert()

          {:ok, updated}
        end
      end)

    ok_count = Enum.count(results, &match?({:ok, _}, &1))

    {:ok, %{retried: ok_count}}
  end

  @doc """
  Gets a scrape URL by URL.
  """
  def get_scrape_url_by_url(url) do
    Repo.get_by(ScrapeUrl, url: url)
  end

  @doc """
  Gets a scrape URL by ID.
  """
  def get_scrape_url(id) do
    Repo.get(ScrapeUrl, id)
  end

  @doc """
  Creates a scrape URL.
  """
  def create_scrape_url(attrs) do
    %ScrapeUrl{}
    |> ScrapeUrl.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a scrape URL.
  """
  def update_scrape_url(%ScrapeUrl{} = scrape_url, attrs) do
    scrape_url
    |> ScrapeUrl.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks a scrape URL as processing.
  """
  def mark_processing(%ScrapeUrl{} = scrape_url) do
    update_scrape_url(scrape_url, %{
      status: "processing",
      attempts: scrape_url.attempts + 1
    })
  end

  @doc """
  Marks a scrape URL as completed with the created recipe.
  """
  def mark_completed(%ScrapeUrl{} = scrape_url, recipe_id) do
    update_scrape_url(scrape_url, %{
      status: "completed",
      recipe_id: recipe_id,
      error: nil
    })
  end

  @doc """
  Marks a scrape URL as failed with an error message.
  """
  def mark_failed(%ScrapeUrl{} = scrape_url, error) do
    update_scrape_url(scrape_url, %{
      status: "failed",
      error: error
    })
  end

  @doc """
  Checks if a URL has already been scraped (completed status).
  """
  def url_scraped?(url) do
    case get_scrape_url_by_url(url) do
      %ScrapeUrl{status: "completed"} -> true
      _ -> false
    end
  end

  @doc """
  Checks if a URL exists in the queue (any status).
  """
  def url_queued?(url) do
    get_scrape_url_by_url(url) != nil
  end

  # Private helpers

  defp extract_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> normalize_domain(host)
      _ -> "unknown"
    end
  end

  defp normalize_domain(domain) do
    domain
    |> String.downcase()
    |> String.replace(~r/^www\./, "")
  end

  @doc """
  Gets current rate limit status.

  Returns hourly/daily counts vs limits.
  """
  def get_rate_limit_status do
    config = Application.get_env(:controlcopypasta, :scraping, [])
    max_per_hour = Keyword.get(config, :max_per_hour, 0)
    max_per_day = Keyword.get(config, :max_per_day, 0)

    hourly_count = get_completed_count_since(hours_ago(1))
    daily_count = get_completed_count_since(hours_ago(24))

    %{
      hourly: %{
        count: hourly_count,
        limit: max_per_hour,
        remaining: max(0, max_per_hour - hourly_count)
      },
      daily: %{
        count: daily_count,
        limit: max_per_day,
        remaining: max(0, max_per_day - daily_count)
      },
      config: %{
        min_delay_ms: Keyword.get(config, :min_delay_ms, 2000),
        max_random_delay_ms: Keyword.get(config, :max_random_delay_ms, 3000),
        browser_pool_size: Application.get_env(:controlcopypasta, :browser_pool_size, 1),
        queue_concurrency: get_queue_concurrency()
      }
    }
  end

  @doc """
  Pauses all scraping by cancelling pending jobs.

  Returns count of cancelled jobs.
  """
  def pause_scraping do
    import Ecto.Query

    # Cancel all pending scrape jobs
    {count, _} =
      Oban.Job
      |> where([j], j.queue == "scraper")
      |> where([j], j.state in ["available", "scheduled", "retryable"])
      |> Repo.update_all(set: [state: "cancelled", cancelled_at: DateTime.utc_now()])

    # Also update our scrape_url records
    ScrapeUrl
    |> where([s], s.status == "pending")
    |> Repo.update_all(set: [status: "paused"])

    {:ok, %{cancelled_jobs: count}}
  end

  @doc """
  Resumes scraping by re-enqueueing paused URLs.

  Returns count of resumed URLs.
  """
  def resume_scraping(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    paused_urls =
      ScrapeUrl
      |> where([s], s.status == "paused")
      |> limit(^limit)
      |> Repo.all()

    results =
      Enum.map(paused_urls, fn scrape_url ->
        with {:ok, updated} <- update_scrape_url(scrape_url, %{status: "pending"}) do
          %{url: updated.url, scrape_url_id: updated.id}
          |> ScrapeWorker.new()
          |> Oban.insert()

          {:ok, updated}
        end
      end)

    ok_count = Enum.count(results, &match?({:ok, _}, &1))
    {:ok, %{resumed: ok_count}}
  end

  defp get_completed_count_since(since) do
    ScrapeUrl
    |> where([s], s.status == "completed")
    |> where([s], s.updated_at >= ^since)
    |> Repo.aggregate(:count)
  end

  defp hours_ago(hours) do
    DateTime.utc_now()
    |> DateTime.add(-hours * 3600, :second)
  end

  defp get_queue_concurrency do
    case Application.get_env(:controlcopypasta, Oban)[:queues] do
      queues when is_list(queues) -> Keyword.get(queues, :scraper, 1)
      _ -> 1
    end
  end
end
