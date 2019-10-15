defmodule RepoGroup do
  defstruct [:name, :description, :url, :items]
end

defmodule Repo do
  defstruct [:name, :description, :url, :stars, :last_commit, :days_ago]
end

defmodule RepoExtInfo do
  defstruct [:url, :stars, :last_commit, :days_ago]
end
