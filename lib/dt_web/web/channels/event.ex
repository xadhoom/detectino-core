defmodule DtWeb.Channels.Event do
  @moduledoc false
  use Phoenix.Channel

  alias DtCore.StatusTracker
  alias DtCore.EventBridge
  alias DtCore.ExitTimerEv
  alias DtCore.DetectorEntryEv

  require Logger

  def join("event:arm", _message, socket) do
    send(self(), :after_join_arm)
    {:ok, socket}
  end

  def join("event:alarm", _message, socket) do
    send(self(), :after_join_alarm)
    {:ok, socket}
  end

  def join("event:alarm_events", _message, socket) do
    send(self(), :after_join_alarm_events)
    {:ok, socket}
  end

  def join("event:exit_timer", _message, socket) do
    EventBridge.start_listening(fn ev ->
      case ev do
        {_, {_, %ExitTimerEv{}}} -> true
        _ -> false
      end
    end)

    {:ok, socket}
  end

  def join("event:entry_timer", _message, socket) do
    EventBridge.start_listening(fn ev ->
      case ev do
        {_, {_, %DetectorEntryEv{}}} -> true
        _ -> false
      end
    end)

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

  def handle_info(:after_join_alarm_events, socket) do
    Etimer.start_link(socket)
    push_unacked_ev_status(socket)
    {:noreply, socket}
  end

  def handle_info({:bridge_ev, _, {action, ev = %ExitTimerEv{}}}, socket)
      when action in [:start, :stop] do
    str_action = Atom.to_string(action)
    push(socket, str_action, %{source: :ExitTimerEv, partition: ev.name})
    {:noreply, socket}
  end

  def handle_info({:bridge_ev, _, {action, ev = %DetectorEntryEv{}}}, socket)
      when action in [:start, :stop] do
    str_action = Atom.to_string(action)
    push(socket, str_action, %{source: :DetectorEntryEv, address: ev.address, port: ev.port})
    {:noreply, socket}
  end

  def handle_info({:bridge_ev, _, _}, socket) do
    {:noreply, socket}
  end

  def push_arm_status(socket) do
    armed = StatusTracker.armed?()
    push(socket, "arm", %{armed: armed})
    Etimer.start_timer(socket, :time, 1000, {__MODULE__, :push_arm_status, [socket]})
  end

  def push_alarm_status(socket) do
    alarmed = StatusTracker.alarmed?()
    push(socket, "alarm", %{alarmed: alarmed})
    Etimer.start_timer(socket, :time, 1000, {__MODULE__, :push_alarm_status, [socket]})
  end

  def push_unacked_ev_status(socket) do
    events = StatusTracker.unacked_events()
    push(socket, "alarm_events", %{events: events})
    Etimer.start_timer(socket, :time, 2_000, {__MODULE__, :push_unacked_ev_status, [socket]})
  end
end
