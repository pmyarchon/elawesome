defmodule ElawesomeWeb.PageController do
  use ElawesomeWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
