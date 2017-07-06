defmodule DtCore.Monitor.Partition do
  @moduledoc """
  Handles the logic of a Partion
  """
  use GenServer

  alias DtCore.EventBridge
  alias DtCore.ArmEv
  alias DtCore.ExitTimerEv
  alias DtCore.DetectorEv
  alias DtCore.DetectorEntryEv
  alias DtCore.DetectorExitEv
  alias DtCore.PartitionEv
  alias DtCore.Monitor.Utils
  alias DtCore.Monitor.Detector
  alias DtCore.Monitor.PartitionFsm
  alias DtCtx.Monitoring.Partition, as: PartitionModel

  require Logger

  # Internal types

  @typep part_state :: %__MODULE__{
    config: %PartitionModel{},
    fsm: pid
  }
  defstruct config: nil,
    fsm: nil

  #
  # Client APIs
  #

  def start_link(config = %PartitionModel{}) do
    {:ok, name} = Utils.partition_server_name(config)
    GenServer.start_link(__MODULE__, {config}, name: name)
  end

  def arming_status(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:arming_status})
  end

  def armed?(server) when is_pid(server) do
    GenServer.call(server, {:armed?})
  end

  def alive?(config = %PartitionModel{}) do
    pid = config
    |> Utils.partition_server_pid
    case pid do
      :undefined -> false
      pid -> pid |> Process.alive?
    end
  end

  def get_pid(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
  end

  def count_sensors(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:count_sensors})
  end

  def arm(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call(:arm)
  end

  def arm(config = %PartitionModel{}, mode)
    when mode in [:normal, :stay, :immediate] do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:arm, mode})
  end

  def disarm(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call(:disarm)
  end

  def alarm_status(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:alarm_status?})
  end

  def alarm_status(server) when is_pid(server) do
    GenServer.call(server, {:alarm_status?})
  end

  def status({config = %PartitionModel{}}) do
    Utils.partition_server_pid(config)
    |> GenServer.call(:status)
  end
  def status(server) when is_pid(server) do
    GenServer.call(server, :status)
  end

  #
  # GenServer Callbacks
  #
  @spec init({%PartitionModel{}}) :: {:ok, part_state}
  def init({config}) do
    Logger.debug fn -> "Starting partition worker with " <>
      "#{inspect config} config" end
    {:ok, fsm} = PartitionFsm.start_link({config, self()})
    state = %__MODULE__{
      config: config,
      fsm: fsm
    }
    subscribe_sensors({config})

    exit_delay = compute_exit_delay(state)
    case config.armed do
      "ARM" ->
        :ok = PartitionFsm.arm(state.fsm, exit_delay)
      "ARMSTAY" ->
        # fake immediate state, because is likely we're recovering
        # from a process crash
        :ok = PartitionFsm.arm(state.fsm, :immediate, exit_delay)
      "ARMSTAYIMMEDIATE" ->
        :ok = PartitionFsm.arm(state.fsm, :immediate, exit_delay)
      _ -> nil
    end

    {:ok, state}
  end

  def handle_call({:armed?}, _from, state) do
    armed = PartitionFsm.armed?(state.fsm)
    {:reply, armed, state}
  end

  def handle_call(:status, _from, state) do
    status = PartitionFsm.status(state.fsm)
    {:reply, status, state}
  end

  def handle_call({:alarm_status?}, _from, state) do
    status = case PartitionFsm.status(state.fsm) do
      :tripped -> :alarm
      _ -> :idle
    end
    {:reply, status, state}
  end

  def handle_call(:arm, _from, state) do
    exit_delay = compute_exit_delay(state)
    res = PartitionFsm.arm(state.fsm, exit_delay)
    {:reply, res, state}
  end

  def handle_call({:arm, :normal}, _from, state) do
    exit_delay = compute_exit_delay(state)
    res = PartitionFsm.arm(state.fsm, exit_delay)
    {:reply, res, state}
  end

  def handle_call({:arm, mode}, _from, state) when mode in [:stay, :immediate] do
    exit_delay = compute_exit_delay(state)
    res = PartitionFsm.arm(state.fsm, mode, exit_delay)
    {:reply, res, state}
  end

  def handle_call(:disarm, _from, state) do
    res = PartitionFsm.disarm(state.fsm)
    {:reply, res, state}
  end

  def handle_info(msg = {_op, _ = %DetectorEv{}}, state) do
    PartitionFsm.event(state.fsm, msg)
    {:noreply, state}
  end

  def handle_info(msg = {_op, ev = %PartitionEv{}}, state) do
    key = %{source: :partition, name: ev.name, type: ev.type}
    EventBridge.dispatch(key, msg)
    {:noreply, state}
  end

  def handle_info(msg = {_op, ev = %ArmEv{}}, state) do
    key = %{source: :partition, name: ev.name}
    EventBridge.dispatch(key, msg)
    {:noreply, state}
  end

  def handle_info(msg = {_op, ev = %ExitTimerEv{}}, state) do
    key = %{source: :partition, name: ev.name}
    EventBridge.dispatch(key, msg)
    {:noreply, state}
  end

  def handle_info({_op, _ = %DetectorExitEv{}}, state) do
    # ignored since not useful to the fsm
    # but maybe makes sense to send it to the fsm in order to be more clear ?
    {:noreply, state}
  end

  def handle_info({_op, _ = %DetectorEntryEv{}}, state) do
    # ignored since not useful to the fsm
    # but maybe makes sense to send it to the fsm in order to be more clear ?
    {:noreply, state}
  end

  def handle_info(any, state) do
    Logger.warn fn() -> "Unhandled info message #{inspect any}" end
    {:noreply, state}
  end

  defp subscribe_sensors({config = %PartitionModel{}}) do
    Enum.each(config.sensors, fn(sensor) ->
      :ok = Detector.subscribe({sensor}, {config.entry_delay, config.exit_delay})
      true = Detector.link({sensor}) # TODO figure out later when sup tree is ready
    end)
  end

  defp compute_exit_delay(state) do
    case state.config.exit_delay do
      nil -> 0
      0 -> 0
      v when is_number(v) -> v * 1000
    end
  end
end
