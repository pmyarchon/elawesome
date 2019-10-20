defmodule Elawesome.Crawler do
  use GenServer
  require Logger

  # Intervals
  @init_interval 1000             # 1 sec
  @retry_interval 1000            # 1 sec
  @verbose_interval 10000         # 10 sec
  @refresh_interval 86400 * 1000  # 1 day

  # GenServer messages
  @msg_refresh_h4cc_repos :refresh_h4cc_repos
  @msg_verbose :verbose
  @msg_debug :debug

  # Statuses
  @status_idle :idle
  @status_parsing_h4cc :parsing_h4cc
  @status_getting_repo_info :getting_repo_info

  # API
  def debug() do
    GenServer.call(__MODULE__, @msg_debug)
  end

  # GenServer API
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_init_arg) do
    Process.send_after(__MODULE__, @msg_refresh_h4cc_repos, @init_interval)
    Process.send_after(__MODULE__, @msg_verbose, @verbose_interval)
    {:ok, %CrawlerState{}}
  end

  # GenServer callbacks
  def handle_call(@msg_debug, _from, state) do
    {:reply, state, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(@msg_verbose, state) do
    if Elawesome.Storage.status() === @status_getting_repo_info do
      num_total = Elawesome.Storage.total()
      num_processed = Elawesome.Storage.processed()
      num_failed = Elawesome.Storage.failed()
      percent = if num_total > 0, do: trunc(100 * (num_processed + num_failed) / num_total), else: 0
      Logger.debug("H4CC update progress: #{percent}%. Total: #{num_total}. Succeeded: #{num_processed}. Failed: #{num_failed}")
    end

    Process.send_after(__MODULE__, @msg_verbose, @verbose_interval)
    {:noreply, state}
  end

  def handle_info(@msg_refresh_h4cc_repos, state) do
    {:ok, pid} = Task.start(&refresh_h4cc_repos/0)
    ref = :erlang.monitor(:process, pid)
    {:noreply, %CrawlerState{state | refresh_pid: pid, refresh_monitor: ref}}
  end

  def handle_info({:DOWN, ref, :process, pid, :normal}, %CrawlerState{refresh_pid: pid, refresh_monitor: ref} = state) do
    Process.send_after(__MODULE__, @msg_refresh_h4cc_repos, @refresh_interval)
    {:noreply, %CrawlerState{state | refresh_pid: nil, refresh_monitor: nil}}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, %CrawlerState{refresh_pid: pid, refresh_monitor: ref} = state) do
    Logger.error("Failed to resfresh H4CC repositories. Reason: #{reason}. Retrying in #{trunc(@retry_interval / 1000)} s...")
    Process.send_after(__MODULE__, @msg_refresh_h4cc_repos, @retry_interval)
    {:noreply, %CrawlerState{state | refresh_pid: nil, refresh_monitor: nil}}
  end

  def terminate(_msg, state) do
    {:noreply, state}
  end

  # Internal functions
  defp refresh_h4cc_repos() do
    # Output debug start
    Logger.debug("H4CC repository update started...")

    # Set warm_up flag if it hasn't ever been set
    if Elawesome.Storage.warm_up? === nil, do: Elawesome.Storage.set_warm_up(true)

    # Set initial status and reset counters
    Elawesome.Storage.set_status(@status_parsing_h4cc)
    Elawesome.Storage.set_h4cc_parse_time(nil)
    Elawesome.Storage.set_repos_info_time(nil)
    Elawesome.Storage.set_total(0)
    Elawesome.Storage.set_processed(0)
    Elawesome.Storage.set_failed(0)

    # Parse H4CC repository
    {time_us1, objects} = :timer.tc(&Utils.Parse.repos/0)

    # Output debug message and update counters
    Logger.debug("H4CC repository parsed in #{trunc(time_us1 / 1000000)} s")
    Elawesome.Storage.set_h4cc_parse_time(time_us1)

    # Process parsed objects
    {time_us2, _} = :timer.tc(fn ->
      for {{group, repos}, index_group} <- List.zip([objects, :lists.seq(1, length(objects))]) do
        Elawesome.Storage.set_repo_group(%RepoGroup{group | order: index_group})

        for {repo, index_repo} <- List.zip([repos, :lists.seq(1, length(repos))]) do
          Elawesome.Storage.set_repo(%Repo{repo | order: index_repo, group: group.name})
        end
      end
    end)

    # Get total number of repositories
    num_repos = Enum.reduce(objects, 0, &(&2 + length(elem(&1, 1))))

    # Output debug message and update counters
    Logger.debug("ETS populated in #{time_us2} us")
    Elawesome.Storage.set_h4cc_parse_time(time_us2)
    Elawesome.Storage.set_total(num_repos)

    # Output debug message and update counters
    Logger.info("Querying GitHub repositories information...")
    Elawesome.Storage.set_status(@status_getting_repo_info)

    # Process parsed objects
    {time_us3, _} = :timer.tc(fn ->
      repos = Elawesome.Storage.repos()
      stream = Task.async_stream(repos, &(get_repo_info(&1)), max_concurrency: 20, timeout: 10000, on_timeout: :kill_task)
      Stream.run(stream)
    end)

    # Output debug message and update counters
    Logger.info("#{num_repos} GitHub repositories checked in #{trunc(time_us3 / 1000000)} s")
    Elawesome.Storage.set_repos_info_time(time_us3)
    Elawesome.Storage.set_status(@status_idle)

    # Output debug end
    num_processed = Elawesome.Storage.processed()
    num_failed = Elawesome.Storage.failed()
    time_us = time_us1 + time_us2 + time_us3
    Logger.debug("H4CC repository update finished in #{trunc(time_us / 1000000)} s. Succeeded: #{num_processed}. Failed: #{num_failed}")
  end

  defp get_repo_info(repo) do
    case Utils.Parse.repo_ext_info(repo.url) do
      %RepoExtInfo{stars: stars, last_commit: last_commit, days_ago: days_ago} ->
        Elawesome.Storage.set_repo(%Repo{repo | stars: stars, last_commit: last_commit, days_ago: days_ago})
        Elawesome.Storage.inc_processed(1)
      :not_exists ->
        Logger.warn("GitHub repository not found: #{repo.url}")
        Elawesome.Storage.delete_repo(repo.name)
        Elawesome.Storage.inc_failed(1)
    end
  end
end
