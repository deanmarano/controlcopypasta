defmodule Mix.Tasks.Scrape.Seed do
  @moduledoc """
  Seed the scrape queue from a JSON file containing URLs.

  Usage:
    mix scrape.seed <json_file>

  The JSON file should be an array of URL strings.

  Examples:
    mix scrape.seed ../scripts/bonappetit-queue.json
  """

  use Mix.Task

  alias Controlcopypasta.Scraper

  @shortdoc "Seed the scrape queue from a JSON file"

  @impl Mix.Task
  def run([]) do
    Mix.shell().error("Error: JSON file path is required")
    Mix.shell().info("\nUsage: mix scrape.seed <json_file>")
    System.halt(1)
  end

  def run([json_file]) do
    Mix.Task.run("app.start")

    case File.read(json_file) do
      {:ok, content} ->
        urls = Jason.decode!(content)
        total = length(urls)

        Mix.shell().info("Found #{total} URLs in #{json_file}")
        Mix.shell().info("Seeding scrape queue...")

        results = Scraper.enqueue_urls(urls)

        Mix.shell().info("\nResults:")
        Mix.shell().info("  Enqueued: #{results.ok}")
        Mix.shell().info("  Skipped (duplicates/errors): #{results.errors}")

      {:error, reason} ->
        Mix.shell().error("Could not read file: #{reason}")
        System.halt(1)
    end
  end

  def run(_) do
    Mix.shell().error("Error: Too many arguments")
    Mix.shell().info("\nUsage: mix scrape.seed <json_file>")
    System.halt(1)
  end
end
