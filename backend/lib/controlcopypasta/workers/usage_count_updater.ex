defmodule Controlcopypasta.Workers.UsageCountUpdater do
  @moduledoc """
  Oban worker that updates ingredient usage counts.

  Runs weekly via cron to recalculate how often each ingredient
  appears across all recipes.

  ## Manual execution

      # Run immediately
      %{}
      |> Controlcopypasta.Workers.UsageCountUpdater.new()
      |> Oban.insert()
  """

  use Oban.Worker,
    queue: :scheduled,
    max_attempts: 1

  require Logger

  alias Controlcopypasta.Ingredients

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("Starting ingredient usage count update...")

    {:ok, %{updated: count}} = Ingredients.update_all_usage_counts()
    Logger.info("Usage count update complete: #{count} ingredients updated")
    :ok
  end
end
