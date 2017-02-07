defmodule DtWeb.Channels.Event do
  use Phoenix.Channel

  alias DtCore.StatusTracker

  require Logger

  def join("event:arm", _message, socket) do
    send(self(), :after_join_arm)
    {:ok, socket}
  end

  def join("event:alarm", _message, socket) do
    send(self(), :after_join_alarm)
    {:ok, socket}
  end

  def handle_info(:after_join_arm, socket) do
    Etimer.start_link(socket)
    push_arm_status(socket)
    {:noreply, socket}
  end

  def handle_info(:after_join_alarm, socket) do
    Etimer.start_link(socket)
    push_alarm_status(socket)
    {:noreply, socket}
  end

  def push_arm_status(socket) do
    armed = StatusTracker.armed?()
    push socket, "event", %{armed: armed}
    Etimer.start_timer(socket, :time, 1000,
      {__MODULE__, :push_arm_status, [socket]}
    )
  end

  def push_alarm_status(socket) do
    alarmed = StatusTracker.alarmed?()
    push socket, "event", %{alarmed: alarmed}
    Etimer.start_timer(socket, :time, 1000,
      {__MODULE__, :push_alarm_status, [socket]}
    )
  end

end
