defmodule SanehRoiRos.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SanehRoiRosWeb.Telemetry,
      SanehRoiRos.Repo,
      {DNSCluster, query: Application.get_env(:saneh_roi_ros, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SanehRoiRos.PubSub},
      # Start a worker by calling: SanehRoiRos.Worker.start_link(arg)
      # {SanehRoiRos.Worker, arg},
      # Start to serve requests, typically the last entry
      SanehRoiRosWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SanehRoiRos.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SanehRoiRosWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
