defmodule Elawesome.Storage do
  use GenServer
  require Logger

  # ETS tables and options
  @ets_props :elawesome_props
  @ets_repo_groups :elawesome_repo_groups
  @ets_repos :elawesome_repos
  @ets_opts [:set, :public, :named_table, {:keypos, 1}]

  # Known property keys
  @p_warm_up :warm_up
  @p_status :status
  @p_total :total_repos
  @p_processed :processed_repos
  @p_failed :failed_repos
  @p_h4cc_parse_time :h4cc_parse_time
  @p_repos_info_time :repos_info_time

  # Intervals
  @init_interval 0

  # Known properties
  def warm_up?(), do: prop(@p_warm_up)

  def set_warm_up(value), do: set_prop(@p_warm_up, value === true)

  def status(), do: prop(@p_status)

  def set_status(value), do: set_prop(@p_status, value)

  def total(), do: prop(@p_total)

  def set_total(value), do: set_prop(@p_total, value)

  def inc_total(value), do: inc_prop(@p_total, value)

  def processed(), do: prop(@p_processed)

  def set_processed(value), do: set_prop(@p_processed, value)

  def inc_processed(value), do: inc_prop(@p_processed, value)

  def failed(), do: prop(@p_failed)

  def set_failed(value), do: set_prop(@p_failed, value)

  def inc_failed(value), do: inc_prop(@p_failed, value)

  def h4cc_parse_time(), do: prop(@p_h4cc_parse_time)

  def set_h4cc_parse_time(value), do: set_prop(@p_h4cc_parse_time, value)

  def repos_info_time(), do: prop(@p_repos_info_time)

  def set_repos_info_time(value), do: set_prop(@p_repos_info_time, value)

  # Property handling
  def prop(key), do: lookup(@ets_props, key, &(elem(&1, 1)))

  def set_prop(key, value), do: :ets.insert(@ets_props, {key, value})

  def inc_prop(key, value), do: :ets.update_counter(@ets_props, key, value)

  def delete_prop(key), do: :ets.delete(@ets_props, key)

  # Repository groups
  def repo_group(name), do: lookup(@ets_repo_groups, name, &RepoGroup.from_tuple/1)

  def set_repo_group(group), do: :ets.insert(@ets_repo_groups, RepoGroup.to_tuple(group))

  def delete_repo_group(name), do: :ets.delete(@ets_repo_groups, name)

  def groups(), do: :ets.foldr(&([RepoGroup.from_tuple(&1) | &2]), [], @ets_repo_groups) |> Enum.sort(&(&1.order <= &2.order))

  # Repositories
  def repo(name), do: lookup(@ets_repos, name, &Repo.from_tuple/1)

  def repos() do
    :ets.foldr(&([Repo.from_tuple(&1) | &2]), [], @ets_repos)
  end

  def filter_repos(min_stars) do
    repos = :ets.foldr(fn (t, acc) ->
      r = Repo.from_tuple(t)
      if r.stars >= min_stars, do: [r | acc], else: acc
    end, [], @ets_repos)

    Enum.sort(repos, &(&1.order <= &2.order))
  end

  def set_repo(repo), do: :ets.insert(@ets_repos, Repo.to_tuple(repo))

  def delete_repo(name), do: :ets.delete(@ets_repos, name)

  # GenServer API
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(init_arg) do
    init_ets_tables()
    Process.send_after(__MODULE__, :init, @init_interval)
    {:ok, init_arg}
  end

  # GenServer callbacks
  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(:init, state) do
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_msg, state) do
    {:noreply, state}
  end

  # Internal functions
  # defp id(value), do: value
  # defp lookup(table, key), do: lookup(table, key, &id/1)

  defp lookup(table, key, conv) do
    case :ets.lookup(table, key) do
      [value | _] -> conv.(value)
      [] -> nil
    end
  end

  defp init_ets_tables do
    # Create ETS tables
    :ets.new(@ets_props, @ets_opts)
    :ets.new(@ets_repo_groups, @ets_opts)
    :ets.new(@ets_repos, @ets_opts)
  end
end
