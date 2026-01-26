defmodule Mix.Tasks.Scrape.Retry do
  @moduledoc """
  Retry failed scrape URLs.

  Usage:
    mix scrape.retry [--domain <domain>]

  Examples:
    mix scrape.retry                        # Retry all failed URLs
    mix scrape.retry --domain bonappetit.com   # Retry failed URLs for specific domain
  """

  use Mix.Task

  alias Controlcopypasta.Scraper

  @shortdoc "Retry failed scrape URLs"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [domain: :string])

    domain = opts[:domain]

    # Show what will be retried
    failed = Scraper.list_failed(domain: domain)

    if Enum.empty?(failed) do
      scope = if domain, do: "for domain #{domain}", else: ""
      Mix.shell().info("No failed URLs #{scope} to retry")
    else
      Mix.shell().info("Found #{length(failed)} failed URL(s) to retry")

      {:ok, result} = Scraper.retry_failed(domain: domain)

      Mix.shell().info("Retried #{result.retried} URL(s)")
      Mix.shell().info("\nThe scraper will process these URLs in the background.")
      Mix.shell().info("Use 'mix scrape.status' to check progress.")
    end
  end
end
