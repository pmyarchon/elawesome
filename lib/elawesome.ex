defmodule Elawesome do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("Elawesome started...", [])
    web_port = Application.get_env(:elawesome, :web_port)
    children = [Plug.Adapters.Cowboy.child_spec(:http, Router, [], port: web_port), Storage]
    Supervisor.start_link(children, [strategy: :one_for_one, name: Elawesome.Supervisor])
  end
end
