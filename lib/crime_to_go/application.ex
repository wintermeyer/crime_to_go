defmodule CrimeToGo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CrimeToGoWeb.Telemetry,
      CrimeToGo.Repo,
      {DNSCluster, query: Application.get_env(:crime_to_go, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CrimeToGo.PubSub},
      # Status logger for debouncing offline/online events
      CrimeToGo.Player.StatusLogger,
      # Start a worker by calling: CrimeToGo.Worker.start_link(arg)
      # {CrimeToGo.Worker, arg},
      # Start to serve requests, typically the last entry
      CrimeToGoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CrimeToGo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CrimeToGoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
