defmodule DtWeb.Channels.Event do
  use Phoenix.Channel

  alias DtCore.StatusTracker

  require Logger

  def join("event:arm", _message, socket) do
    {:ok, socket}
  end

  def join("event:alarm", _message, socket) do
    send(self(), :after_join_alarm)
    {:ok, socket}
  end

  def handle_info(:after_join_alarm, socket) do
    Etimer.start_link(socket)
    push_status(socket)
    {:noreply, socket}
  end

  def push_status(socket) do
    alarmed = StatusTracker.alarm_status()
    push socket, "event", %{alarmed: alarmed}
    Etimer.start_timer(socket, :time, 1000, {__MODULE__, :push_status, [socket]})
  end

end
