defmodule Utils do
  def timestamp do
    :os.system_time(:seconds)
  end

  def get_contents(url) do
    case :httpc.request(:get, {to_charlist(url), []}, [], [{:body_format, :binary}]) do
      {:ok, {{_version, _, _status_text}, _headers, body}} -> {:ok, body}
      _ -> nil
    end
  end

  def maybe_int(nil, default), do: default
  def maybe_int(value, _) when is_integer(value), do: value
  def maybe_int(value, _) when is_binary(value), do: :erlang.binary_to_integer(value)
end
