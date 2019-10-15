defmodule Utils do
  def timestamp do
    :os.system_time(:seconds)
  end

  def get_contents(url) do
    case :httpc.request(:get, {to_charlist(url), []}, [], [{:body_format, :binary}]) do
      {:ok, {{_version, 200, _status_text}, _headers, body}} -> {:ok, body}
      _ -> nil
    end
  end
end
