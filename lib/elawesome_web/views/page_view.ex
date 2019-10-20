defmodule ElawesomeWeb.PageView do
  use ElawesomeWeb, :view

  def to_anchor(url), do: String.trim_leading(url, "#")
end
