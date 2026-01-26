defmodule Mix.Tasks.Scrape.Add do
  @moduledoc """
  Add specific URLs to the scrape queue.

  Usage:
    mix scrape.add <url1> [<url2> ...]

  Examples:
    mix scrape.add https://www.bonappetit.com/recipe/pasta-with-tomato-sauce

    mix scrape.add \\
      https://www.seriouseats.com/pizza-recipe \\
      https://www.seriouseats.com/pasta-recipe
  """

  use Mix.Task

  alias Controlcopypasta.Scraper

  @shortdoc "Add URLs to the scrape queue"

  @impl Mix.Task
  def run([]) do
    Mix.shell().error("Error: At least one URL is required")
    Mix.shell().info("\nUsage: mix scrape.add <url1> [<url2> ...]")
    System.halt(1)
  end

  def run(urls) do
    Mix.Task.run("app.start")

    Mix.shell().info("Adding #{length(urls)} URL(s) to scrape queue...")

    results = Scraper.enqueue_urls(urls)

    Mix.shell().info("\nResults:")
    Mix.shell().info("  Enqueued: #{results.ok}")
    Mix.shell().info("  Errors/duplicates: #{results.errors}")
  end
end
