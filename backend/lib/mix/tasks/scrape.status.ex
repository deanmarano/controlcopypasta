defmodule Mix.Tasks.Scrape.Status do
  @moduledoc """
  Show scrape queue status.

  Usage:
    mix scrape.status [--domain <domain>]

  Examples:
    mix scrape.status
    mix scrape.status --domain bonappetit.com
  """

  use Mix.Task

  alias Controlcopypasta.Scraper

  @shortdoc "Show scrape queue status"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [domain: :string])

    case opts[:domain] do
      nil -> show_overall_status()
      domain -> show_domain_status(domain)
    end
  end

  defp show_overall_status do
    stats = Scraper.get_scrape_stats()

    Mix.shell().info("Scrape Queue Status")
    Mix.shell().info("==================")
    Mix.shell().info("")
    Mix.shell().info("  Total:      #{stats["total"]}")
    Mix.shell().info("  Pending:    #{stats["pending"]}")
    Mix.shell().info("  Processing: #{stats["processing"]}")
    Mix.shell().info("  Completed:  #{stats["completed"]}")
    Mix.shell().info("  Failed:     #{stats["failed"]}")

    Mix.shell().info("")
    Mix.shell().info("By Domain:")
    Mix.shell().info("---------")

    domain_stats = Scraper.get_domain_stats()

    if Enum.empty?(domain_stats) do
      Mix.shell().info("  No URLs in queue")
    else
      domain_stats
      |> Enum.each(fn stat ->
        Mix.shell().info(
          "  #{stat.domain}: #{stat.completed}/#{stat.total} completed, #{stat.failed} failed"
        )
      end)
    end
  end

  defp show_domain_status(domain) do
    Mix.shell().info("Status for domain: #{domain}")
    Mix.shell().info("=" |> String.duplicate(40))

    stats = Scraper.get_domain_stats(domain)

    case stats do
      [] ->
        Mix.shell().info("No URLs found for domain: #{domain}")

      [stat | _] ->
        Mix.shell().info("")
        Mix.shell().info("  Total:      #{stat.total}")
        Mix.shell().info("  Pending:    #{stat.pending}")
        Mix.shell().info("  Processing: #{stat.processing}")
        Mix.shell().info("  Completed:  #{stat.completed}")
        Mix.shell().info("  Failed:     #{stat.failed}")

        if stat.failed > 0 do
          Mix.shell().info("")
          Mix.shell().info("Recent failures:")

          Scraper.list_failed(domain: domain, limit: 5)
          |> Enum.each(fn scrape_url ->
            Mix.shell().info("  - #{scrape_url.url}")
            Mix.shell().info("    Error: #{scrape_url.error}")
          end)
        end
    end
  end
end
