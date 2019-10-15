defmodule Repo do
  defstruct [:name, :description, :url, :stars, :last_commit]
end

defmodule RepoGroup do
  defstruct [:name, :description, :url, :items]
end

