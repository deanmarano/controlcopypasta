defmodule ControlcopypastaWeb.Admin.ScraperController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Scraper

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
end
