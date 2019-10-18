defmodule ElawesomeWeb.LayoutView do
  use ElawesomeWeb, :view

  def robots(conn) do
    case conn.assigns[:robots] do
      nil -> "noindex, nofollow"
      robots -> robots
    end
  end

  def title(conn) do
    case conn.assigns[:title] do
      nil -> "Elawesome example application"
      title -> title
    end
  end
end
