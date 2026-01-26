defmodule Mix.Tasks.Scrape do
  @moduledoc """
  Start crawling a domain with seed URLs.

  Usage:
    mix scrape <domain> --seed <url1> [--seed <url2> ...]

  Examples:
    mix scrape bonappetit.com --seed https://www.bonappetit.com/recipes

    mix scrape seriouseats.com \\
      --seed https://www.seriouseats.com/recipes \\
      --seed https://www.seriouseats.com/quick-recipes
  """

  use Mix.Task

  alias Controlcopypasta.Scraper

  @shortdoc "Start crawling a domain with seed URLs"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, rest, _invalid} = OptionParser.parse(args, strict: [seed: :keep])

    seed_urls = Keyword.get_values(opts, :seed)

    case rest do
      [domain] when seed_urls != [] ->
        start_crawl(domain, seed_urls)

      [_domain] ->
        Mix.shell().error("Error: At least one --seed URL is required")
        Mix.shell().info("\nUsage: mix scrape <domain> --seed <url>")
        System.halt(1)

      [] ->
        Mix.shell().error("Error: Domain argument is required")
        Mix.shell().info("\nUsage: mix scrape <domain> --seed <url>")
        System.halt(1)

      _ ->
        Mix.shell().error("Error: Too many arguments")
        Mix.shell().info("\nUsage: mix scrape <domain> --seed <url>")
        System.halt(1)
    end
  end

  defp start_crawl(domain, seed_urls) do
    Mix.shell().info("Starting crawl of #{domain}")
    Mix.shell().info("Seed URLs: #{length(seed_urls)}")

    {:ok, result} = Scraper.enqueue_domain(domain, seed_urls)

    Mix.shell().info("\nEnqueued #{result.enqueued} URLs for domain: #{result.domain}")

    if result.errors > 0 do
      Mix.shell().info("Errors: #{result.errors}")
    end

    Mix.shell().info("\nThe scraper will process these URLs in the background.")
    Mix.shell().info("Use 'mix scrape.status' to check progress.")
  end
end
