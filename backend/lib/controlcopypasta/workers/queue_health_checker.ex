defmodule Controlcopypasta.Workers.QueueHealthChecker do
  @moduledoc """
  Scheduled worker that monitors Oban queue health and fixes common issues.

  Detects and resolves:
  - Stuck executing jobs (jobs that have been executing too long)
  - Paused queues that should be running
  - Jobs in inconsistent state (e.g., available but with completed_at set)

  Runs every 5 minutes via Oban cron.
  """

  use Oban.Worker,
    queue: :scheduled,
    max_attempts: 1

  require Logger

  import Ecto.Query
  alias Controlcopypasta.Repo

  # Jobs executing longer than this are considered stuck
  @stuck_threshold_minutes 30

  # Queues to monitor
  @monitored_queues [:nutrition, :density, :fatsecret, :scraper]

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("QueueHealthChecker: Starting health check")

    reset_stuck_jobs()
    fix_inconsistent_jobs()
    resume_paused_queues()

    Logger.info("QueueHealthChecker: Health check complete")
    :ok
  end

  @doc """
  Resets jobs that have been executing for too long.
  These are likely from crashed workers or network timeouts.
  """
  def reset_stuck_jobs do
    stuck_threshold = DateTime.add(DateTime.utc_now(), -@stuck_threshold_minutes * 60, :second)

    {count, _} =
      Oban.Job
      |> where([j], j.state == "executing")
      |> where([j], j.attempted_at < ^stuck_threshold)
      |> Repo.update_all(set: [
        state: "available",
        attempted_at: nil,
        attempted_by: nil
      ])

    if count > 0 do
      Logger.warning("QueueHealthChecker: Reset #{count} stuck executing jobs")
    end

    count
  end

  @doc """
  Fixes jobs in inconsistent state.
  For example, jobs marked as 'available' but with completed_at set
  (can happen when using Oban's replace option).
  """
  def fix_inconsistent_jobs do
    # Fix available jobs that have completed_at set
    {count, _} =
      Oban.Job
      |> where([j], j.state == "available")
      |> where([j], not is_nil(j.completed_at))
      |> Repo.update_all(set: [
        completed_at: nil,
        attempt: 0,
        errors: []
      ])

    if count > 0 do
      Logger.warning("QueueHealthChecker: Fixed #{count} jobs with inconsistent state")
    end

    count
  end

  @doc """
  Resumes any paused queues that should be running.
  """
  def resume_paused_queues do
    Enum.each(@monitored_queues, fn queue ->
      case Oban.check_queue(queue: queue) do
        %{paused: true} ->
          Logger.warning("QueueHealthChecker: Resuming paused queue #{queue}")
          Oban.resume_queue(queue: queue)

        %{running: running, limit: limit} when length(running) == 0 and limit > 0 ->
          # Queue not paused but not processing - try resuming anyway
          check_queue_activity(queue)

        _ ->
          :ok
      end
    end)
  end

  # Check if a queue has available jobs but isn't processing
  defp check_queue_activity(queue) do
    queue_name = Atom.to_string(queue)

    available_count =
      Oban.Job
      |> where([j], j.queue == ^queue_name)
      |> where([j], j.state == "available")
      |> where([j], j.scheduled_at <= ^DateTime.utc_now())
      |> Repo.aggregate(:count)

    if available_count > 0 do
      Logger.warning("QueueHealthChecker: Queue #{queue} has #{available_count} available jobs but none executing, resuming")
      Oban.resume_queue(queue: queue)
    end
  end

  @doc """
  Returns health status for all monitored queues.
  Useful for admin dashboard.
  """
  def health_status do
    Enum.map(@monitored_queues, fn queue ->
      queue_name = Atom.to_string(queue)

      counts =
        Oban.Job
        |> where([j], j.queue == ^queue_name)
        |> group_by([j], j.state)
        |> select([j], {j.state, count(j.id)})
        |> Repo.all()
        |> Map.new()

      oban_status =
        try do
          Oban.check_queue(queue: queue)
        rescue
          _ -> %{paused: false, running: [], limit: 0}
        end

      %{
        queue: queue,
        available: counts["available"] || 0,
        executing: counts["executing"] || 0,
        completed: counts["completed"] || 0,
        discarded: counts["discarded"] || 0,
        paused: oban_status[:paused] || false,
        running_count: length(oban_status[:running] || []),
        limit: oban_status[:limit] || 0
      }
    end)
  end
end
