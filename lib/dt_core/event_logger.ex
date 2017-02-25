defmodule DtCore.EventLogger do
  @moduledoc """
  Module responsible of receiving events and logging to database and files
  """
  use GenServer

  alias DtCore.EventBridge
  alias DtCore.ArmEv
  alias DtCore.SensorEv
  alias DtCore.PartitionEv
  alias DtCore.ExitTimerEv
  alias DtWeb.EventLog
  alias DtWeb.Repo

  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    Logger.info "Starting Event Logger"
    EventBridge.start_listening(fn ev -> filter(ev) end)
    {:ok, nil}
  end

  def handle_info({:bridge_ev, _, {op, ev = %ArmEv{}}}, state) do
    operation = Atom.to_string(op)
    %{type: "arm", operation: operation, details: ev}
    |> save_eventlog()

    {:noreply, state}
  end

  def handle_info({:bridge_ev, _, {op, ev = %ExitTimerEv{}}}, state) do
    operation = Atom.to_string(op)
    %{type: "exit_timer", operation: operation, details: ev}
    |> save_eventlog()

    {:noreply, state}
  end

  def handle_info({:bridge_ev, _, {_, %SensorEv{type: :reading}}}, state) do
    {:noreply, state}
  end

  def handle_info({:bridge_ev, _, {op, ev = %SensorEv{}}}, state) do
    operation = Atom.to_string(op)
    %{type: "alarm", operation: operation, details: ev}
    |> save_eventlog()

    {:noreply, state}
  end

  def handle_info({:bridge_ev, _, {op, ev = %PartitionEv{}}}, state) do
    operation = Atom.to_string(op)
    %{type: "alarm", operation: operation, details: ev} |> save_eventlog()
    {:noreply, state}
  end

  def filter({_, {_, %ArmEv{}}}) do
    true
  end

  def filter({_, {_, %SensorEv{}}}) do
    true
  end

  def filter({_, {_, %PartitionEv{}}}) do
    true
  end

  def filter({_, {_, %ExitTimerEv{}}}) do
    true
  end

  defp save_eventlog(params) do
    EventLog.create_changeset(%EventLog{}, params)
    |> Repo.insert!
  end

end
