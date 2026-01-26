defmodule Controlcopypasta.Workers.ScraperUnpauser do
  @moduledoc """
  Periodically checks if scraper rate limits have relaxed and resumes the queue.

  Runs every 5 minutes via cron. If the scraper queue is paused and we're
  under the rate limits, it resumes the queue.
  """

  use Oban.Worker,
    queue: :scheduled,
    max_attempts: 1

  require Logger

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Scraper.ScrapeUrl
  import Ecto.Query

  @impl Oban.Worker
  def perform(_job) do
    if under_rate_limits?() do
      Logger.info("Rate limits OK, resuming scraper queue")
      Oban.resume_queue(queue: :scraper)
    end

    :ok
  end

  defp under_rate_limits? do
    config = Application.get_env(:controlcopypasta, :scraping, [])
    max_per_hour = Keyword.get(config, :max_per_hour, 0)
    max_per_day = Keyword.get(config, :max_per_day, 0)

    hourly_ok = max_per_hour == 0 || count_completed_since(hours: 1) < max_per_hour
    daily_ok = max_per_day == 0 || count_completed_since(hours: 24) < max_per_day

    hourly_ok && daily_ok
  end

  defp count_completed_since(hours: hours) do
    since = DateTime.utc_now() |> DateTime.add(-hours * 3600, :second)

    ScrapeUrl
    |> where([s], s.status == "completed")
    |> where([s], s.updated_at >= ^since)
    |> Repo.aggregate(:count)
  end
end
