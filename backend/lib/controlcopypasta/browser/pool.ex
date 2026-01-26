defmodule Controlcopypasta.Browser.Pool do
  @moduledoc """
  A pool of browser workers using NimblePool.
  Provides efficient reuse of Playwright browser instances.
  """

  @behaviour NimblePool

  alias Controlcopypasta.Browser.Worker

  @default_pool_size 2
  @checkout_timeout 40_000

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  def start_link(opts \\ []) do
    pool_size =
      opts[:pool_size] ||
        Application.get_env(:controlcopypasta, :browser_pool_size, @default_pool_size)

    NimblePool.start_link(
      worker: {__MODULE__, opts},
      pool_size: pool_size,
      name: __MODULE__
    )
  end

  @doc """
  Fetches HTML from the given URL using a pooled browser worker.
  Returns {:ok, html} or {:error, reason}.
  """
  def fetch_html(url, opts \\ []) do
    timeout = opts[:timeout] || @checkout_timeout

    NimblePool.checkout!(
      __MODULE__,
      :checkout,
      fn _from, worker ->
        result = Worker.fetch_html(worker, url, timeout - 5_000)
        # Return {result, :ok} to indicate worker is healthy
        # Return {result, {:error, reason}} to indicate worker should be removed
        case result do
          {:ok, _html} -> {result, :ok}
          {:error, :port_crashed} -> {result, {:error, :crashed}}
          {:error, _} -> {result, :ok}
        end
      end,
      timeout
    )
  catch
    :exit, {:timeout, _} ->
      {:error, "Browser pool checkout timeout"}
  end

  @doc """
  Checks pool health by pinging a worker.
  Returns :pong or {:error, reason}.
  """
  def health_check do
    NimblePool.checkout!(
      __MODULE__,
      :checkout,
      fn _from, worker ->
        result = Worker.ping(worker)
        {result, :ok}
      end,
      5_000
    )
  rescue
    _ -> {:error, :health_check_failed}
  end

  # NimblePool callbacks

  @impl NimblePool
  def init_worker(opts) do
    case Worker.start_link(opts) do
      {:ok, worker} ->
        {:ok, worker, opts}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, worker, pool_state) do
    {:ok, worker, worker, pool_state}
  end

  @impl NimblePool
  def handle_checkin(:ok, _from, worker, pool_state) do
    {:ok, worker, pool_state}
  end

  def handle_checkin({:error, :crashed}, _from, _worker, pool_state) do
    # Worker crashed, remove it from pool (will be replaced)
    {:remove, :crashed, pool_state}
  end

  def handle_checkin({:error, _reason}, _from, worker, pool_state) do
    # Other errors, keep the worker but verify it's healthy
    case Worker.ping(worker, 2_000) do
      :pong -> {:ok, worker, pool_state}
      _ -> {:remove, :unhealthy, pool_state}
    end
  end

  @impl NimblePool
  def terminate_worker(_reason, worker, pool_state) do
    try do
      GenServer.stop(worker, :normal, 5_000)
    rescue
      _ -> :ok
    end

    {:ok, pool_state}
  end
end
