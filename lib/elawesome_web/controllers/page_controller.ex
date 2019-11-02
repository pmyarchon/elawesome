defmodule ElawesomeWeb.PageController do
  use ElawesomeWeb, :controller

  def index(conn, params) do
    # Get minimal stars
    min_stars = Utils.maybe_int(params["min_stars"], 0)

    # Filter repositories
    warm_up = Elawesome.Storage.warm_up?

    items = if not warm_up do
      repos = Elawesome.Storage.filter_repos(min_stars)
      group_keys = Enum.reduce(repos, MapSet.new(), &(MapSet.put(&2, &1.group)))
      Elawesome.Storage.groups()
        |> Enum.filter(&(MapSet.member?(group_keys, &1.name)))
        |> Enum.map(&(%{group: &1, repos: Enum.filter(repos, fn el -> el.group === &1.name end)}))
        |> Enum.filter(&(&1[:items] !== []))
    else
      []
    end

    render conn, "index.html",
      ready: not warm_up,
      min_stars: min_stars,
      num_total: Elawesome.Storage.total,
      num_processed: Elawesome.Storage.processed,
      num_failed: Elawesome.Storage.failed,
      items: items
  end
end
