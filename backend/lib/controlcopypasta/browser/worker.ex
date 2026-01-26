defmodule Controlcopypasta.Browser.Worker do
  @moduledoc """
  GenServer that wraps a Port to a long-running Node.js Playwright process.
  Handles request/response correlation and automatic port restart on crash.
  """

  use GenServer
  require Logger

  @default_timeout 35_000
  @max_line_length 10_000_000

  defstruct [:port, :pending, :script_path]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Fetches HTML from the given URL using the browser.
  Returns {:ok, html} or {:error, reason}.
  """
  def fetch_html(worker, url, timeout \\ @default_timeout) do
    GenServer.call(worker, {:fetch, url, timeout}, timeout)
  end

  @doc """
  Pings the worker to check if it's responsive.
  Returns :pong or {:error, reason}.
  """
  def ping(worker, timeout \\ 5_000) do
    GenServer.call(worker, :ping, timeout)
  end

  # Callbacks

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    script_path = opts[:script_path] || default_script_path()

    case open_port(script_path) do
      {:ok, port} ->
        {:ok, %__MODULE__{port: port, pending: %{}, script_path: script_path}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:fetch, url, timeout}, from, state) do
    id = generate_id()
    node_timeout = max(timeout - 5_000, 10_000)
    command = %{type: "fetch", id: id, url: url, timeout: node_timeout}

    case send_command(state.port, command) do
      :ok ->
        pending = Map.put(state.pending, id, from)
        {:noreply, %{state | pending: pending}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:ping, from, state) do
    id = generate_id()
    command = %{type: "ping", id: id}

    case send_command(state.port, command) do
      :ok ->
        pending = Map.put(state.pending, id, from)
        {:noreply, %{state | pending: pending}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info({port, {:data, {:eol, data}}}, %{port: port} = state) do
    case Jason.decode(data) do
      {:ok, %{"id" => id, "status" => "ok", "html" => html}} ->
        reply_and_remove(state, id, {:ok, html})

      {:ok, %{"id" => id, "status" => "error", "error" => error}} ->
        reply_and_remove(state, id, {:error, error})

      {:ok, %{"id" => id, "status" => "pong"}} ->
        reply_and_remove(state, id, :pong)

      {:ok, other} ->
        Logger.warning("Unexpected response from browser worker: #{inspect(other)}")
        {:noreply, state}

      {:error, _} ->
        Logger.warning("Invalid JSON from browser worker: #{inspect(data)}")
        {:noreply, state}
    end
  end

  def handle_info({port, {:data, {:noeol, _data}}}, %{port: port} = state) do
    # Partial line, wait for more data
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.error("Browser worker port exited with status: #{status}")
    handle_port_crash(state)
  end

  def handle_info({:EXIT, port, reason}, %{port: port} = state) do
    Logger.error("Browser worker port crashed: #{inspect(reason)}")
    handle_port_crash(state)
  end

  def handle_info(msg, state) do
    Logger.debug("Browser worker received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.port do
      send_command(state.port, %{type: "shutdown"})
      Port.close(state.port)
    end

    :ok
  end

  # Private functions

  defp open_port(script_path) do
    node_path = System.find_executable("node")

    if node_path do
      port =
        Port.open(
          {:spawn_executable, node_path},
          [
            :binary,
            :exit_status,
            {:line, @max_line_length},
            {:args, [script_path]},
            {:cd, scripts_dir()},
            {:env, []}
          ]
        )

      {:ok, port}
    else
      {:error, :node_not_found}
    end
  end

  defp send_command(port, command) do
    try do
      json = Jason.encode!(command)
      Port.command(port, [json, "\n"])
      :ok
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp reply_and_remove(state, id, reply) do
    case Map.pop(state.pending, id) do
      {nil, _} ->
        Logger.warning("Received response for unknown request: #{id}")
        {:noreply, state}

      {from, pending} ->
        GenServer.reply(from, reply)
        {:noreply, %{state | pending: pending}}
    end
  end

  defp handle_port_crash(state) do
    # Reply error to all pending requests
    for {_id, from} <- state.pending do
      GenServer.reply(from, {:error, :port_crashed})
    end

    # Try to restart the port
    case open_port(state.script_path) do
      {:ok, new_port} ->
        Logger.info("Browser worker port restarted")
        {:noreply, %{state | port: new_port, pending: %{}}}

      {:error, reason} ->
        Logger.error("Failed to restart browser worker port: #{inspect(reason)}")
        {:stop, :port_restart_failed, state}
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp scripts_dir do
    # Get the project root (parent of backend directory)
    # In dev: /path/to/controlcopypasta/backend -> /path/to/controlcopypasta/scripts
    # Check for scripts relative to the current working directory first
    cwd_scripts = Path.join([File.cwd!(), "..", "scripts"]) |> Path.expand()

    if File.dir?(cwd_scripts) do
      cwd_scripts
    else
      # Fallback: try relative to the app directory
      Path.join([Application.app_dir(:controlcopypasta), "..", "..", "..", "scripts"])
      |> Path.expand()
    end
  end

  defp default_script_path do
    Path.join(scripts_dir(), "browser-worker.js")
  end
end
