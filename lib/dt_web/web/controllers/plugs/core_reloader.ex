defmodule DtWeb.Plugs.CoreReloader do
  @moduledoc false
  import Plug.Conn

  alias DtWeb.ReloadRegistry

  require Logger

  def init(default), do: default

  def call(conn, _default) do
    register_before_send(conn, fn conn ->
      callback(conn)
    end)
  end

  defp callback(conn) do
    case Map.get(conn, :status) do
      x when is_integer(x) and x < 300 ->
        do_reload()

      _ ->
        nil
    end

    conn
  end

  defp do_reload do
    Logger.debug("Reloading Configuration")

    Registry.dispatch(ReloadRegistry.registry(), ReloadRegistry.key(), fn listeners ->
      for {pid, _} <- listeners, do: send(pid, {:reload})
    end)
  end
end
