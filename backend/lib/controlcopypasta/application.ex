defmodule Controlcopypasta.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ControlcopypastaWeb.Telemetry,
      Controlcopypasta.Repo,
      {DNSCluster, query: Application.get_env(:controlcopypasta, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Controlcopypasta.PubSub},
      # Parser vocabulary cache (loads preparations + normalizer from DB)
      Controlcopypasta.Ingredients.ParserCache,
      # Per-user avoided ingredient cache (ETS with 5-min TTL)
      Controlcopypasta.Quicklist.AvoidedCache,
      # Start to serve requests, typically the last entry
      ControlcopypastaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Controlcopypasta.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ControlcopypastaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
