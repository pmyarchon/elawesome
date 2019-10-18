defmodule ElawesomeWeb.PageView do
  use ElawesomeWeb, :view

  def libs(conn) do
    # min_stars = case conn.params["min_stars"] do
    #   stars when is_binary(stars) -> :erlang.binary_to_integer(stars)
    #   _ -> 0
    # end
    # "Show repos with at least of #{min_stars} stars"

    Utils.Parse.repos()
  end
end
