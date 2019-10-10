defmodule Storage do
  use GenServer
  require Logger

  @compile {:parse_transform, :ms_transform}  # Enable MatchSpec parse transform

  @init_interval 0
  @refresh_interval 10000
  @ets_table :repos
  @ets_opts [:set, :public, :named_table, {:keypos, 1}]

  # API
  def lookup(key) do
    result = :ets.lookup(@ets_table, key)
    case result do
      [entry|_] -> entry
      [] -> nil
    end
  end

  def set(url, category, stars, last_commit_ts) do
    :ets.insert(@ets_table, mk_tuple(url, category, stars, last_commit_ts))
  end

  def delete(url) do
    :ets.delete(@ets_table, url)
  end

  def delete_all() do
    :ets.delete_all_objects(@ets_table)
  end

  # GenServer API
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(init_arg) do
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
    :ets.new(@ets_table, @ets_opts)
    Process.send_after(__MODULE__, :refresh, @refresh_interval)
    {:noreply, state}
  end

  def handle_info(:refresh, state) do
    # cleanup_expired()
    Process.send_after(__MODULE__, :refresh, @refresh_interval)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_msg, state) do
    {:noreply, state}
  end

  # Internal functions
  defp mk_tuple(url, category, stars, last_commit_ts) do
    {url, category, stars, last_commit_ts}
  end

  # defp cleanup_expired() do
  #   now = Utils.timestamp()

  #   match_spec = :ets.fun2ms(fn({_, _, _, valid_thru}) when valid_thru < now -> true end)
  #   num_deleted = :dets.select_delete(@db_table, match_spec)

  #   if num_deleted > 0 do
  #     Logger.debug("#{num_deleted} keys expired and cleaned...")
  #   end
  # end
end
