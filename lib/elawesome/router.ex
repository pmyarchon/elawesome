defmodule Router do
  use Plug.Router
  require Logger

  # @param_min_stars "min_stars"

  plug :match
  plug :dispatch

  # Read
  get "/" do
    # min_stars
    # {status, body} = case Storage.lookup(key) do
    #   nil -> {404, "Not found"}
    #   {_, value, _, _} -> {200, value}
    #   {:error, _reason} -> {500, "Internal server error"}
    # end

    # Logger.debug("GET /#{key} -> #{status} #{body}")
    send_resp(conn, 200, "OK")
  end

  # Catch-up
  match _ do
    send_resp(conn, 404, "Not found")
  end
end
