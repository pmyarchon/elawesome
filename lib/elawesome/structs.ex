defmodule RepoGroup do
  defstruct [:name, :description, :url, :order]

  def to_tuple(g), do: {g.name, g.description, g.url, g.order}

  def from_tuple(t), do: %RepoGroup{name: elem(t, 0), description: elem(t, 1), url: elem(t, 2), order: elem(t, 3)}
end

defmodule Repo do
  defstruct [:name, :description, :url, :stars, :last_commit, :days_ago, :order, :group]

  def to_tuple(r), do: {r.name, r.description, r.url, r.stars, r.last_commit, r.days_ago, r.order, r.group}

  def from_tuple(t), do: %Repo{name: elem(t, 0), description: elem(t, 1), url: elem(t, 2), stars: elem(t, 3), last_commit: elem(t, 4), days_ago: elem(t, 5), order: elem(t, 6), group: elem(t, 7)}
end

defmodule RepoExtInfo do
  defstruct [:name, :stars, :last_commit, :days_ago]
end

defmodule CrawlerState do
  defstruct [:refresh_pid, :refresh_monitor]
end
