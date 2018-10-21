defmodule DtWeb.Channels.Timer do
  @moduledoc false
  use Phoenix.Channel

  require Logger

  def join("timer:time", _message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    Etimer.start_link(socket)
    push_time(socket)
    {:noreply, socket}
  end

  def push_time(socket) do
    time =
      Timex.local()
      |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)

    push(socket, "time", %{time: time})
    Etimer.start_timer(socket, :time, 1000, {__MODULE__, :push_time, [socket]})
  end
end
