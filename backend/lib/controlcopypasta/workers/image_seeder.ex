defmodule Controlcopypasta.Workers.ImageSeeder do
  @moduledoc """
  Oban worker that seeds ingredient images from Spoonacular.

  Runs daily via cron to fetch images for ingredients that don't have them.
  Respects Spoonacular's daily API quota by stopping when limit is reached.

  ## Manual execution

      # Run immediately
      %{}
      |> Controlcopypasta.Workers.ImageSeeder.new()
      |> Oban.insert()

  ## Configuration

  Set SPOONACULAR_API_KEY environment variable.
  """

  use Oban.Worker,
    queue: :scheduled,
    max_attempts: 1

  require Logger

  alias Controlcopypasta.Nutrition.Seeder
  alias Controlcopypasta.Nutrition.SpoonacularClient

  @impl Oban.Worker
  def perform(_job) do
    if SpoonacularClient.api_key_configured?() do
      Logger.info("Starting scheduled image seeding...")

      result = Seeder.seed_images()

      Logger.info(
        "Image seeding complete: #{result.success} succeeded, #{result.failed} failed"
      )

      :ok
    else
      Logger.warning("Skipping image seeding - SPOONACULAR_API_KEY not configured")
      :ok
    end
  end
end
