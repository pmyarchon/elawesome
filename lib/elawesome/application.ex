defmodule Elawesome.Application do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec

    # Say hello!
    Logger.debug("Elawesome started...", [])

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(ElawesomeWeb.Endpoint, []),

      # Start Storage gen_server
      Storage
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html for other strategies and supported options
    opts = [strategy: :one_for_one, name: Elawesome.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration whenever the application is updated
  def config_change(changed, _new, removed) do
    ElawesomeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
