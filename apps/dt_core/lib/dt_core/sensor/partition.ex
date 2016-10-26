defmodule DtCore.Sensor.Partition do
  @moduledoc """
  Handles the logic of a Partion
  """
  use GenServer

  require Logger
  alias DtCore.Sensor.Utils
  alias DtCore.Sensor.Worker
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event
  alias DtCore.SensorEv
  alias DtCore.PartitionEv

  @arm_modes ["ARM", "ARMSTAY", "ARMSTAYIMMEDIATE"]
  @disarm_modes ["DISARM"]

  def start_link({config = %PartitionModel{}, receiver}) do
    {:ok, name} = Utils.partition_server_name(config)
    GenServer.start_link(__MODULE__, {config, receiver}, name: name)
  end

  def arming_status(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:arming_status})
  end

  def alive?(config = %PartitionModel{}) do
    pid = config
    |> Utils.partition_server_pid
    case pid do
      :undefined -> false
      pid -> pid |> Process.alive?
    end
  end

  def count_sensors(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:count_sensors})
  end

  def arm(config = %PartitionModel{}, mode) when mode in @arm_modes do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:arm, mode})
  end

  def disarm(config = %PartitionModel{}, mode) when mode in @disarm_modes do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:disarm, mode})
  end

  #
  # GenServer Callbacks
  #
  def init({config, receiver}) do
    Logger.debug("Starting partition worker with " <>
      "#{inspect config} config")
    state = %{
      config: config,
      receiver: receiver,
      sensors: []
    }
    send self(), {:start}
    {:ok, state}
  end

  def handle_info({:start}, state) do
    sensors_pids = state.config.sensors
    |> Enum.reduce([], fn(sensor, acc) ->
      case Worker.start_link({sensor, state.config, self}) do
        {:ok, pid} ->
          Process.monitor pid
          acc ++ [pid]
        {:error, what} ->
          Logger.error "Cannot start Sensor, #{inspect what}"
          acc
      end
    end)
    {:noreply, %{state | sensors: sensors_pids}}
  end

  def handle_info({:event, ev = %Event{}}, state) do
    Logger.debug "Received event #{inspect ev} from server"

    state.sensors
    |> Enum.each(fn(pid) ->
      Logger.debug "Sending event #{inspect ev} to sensor #{inspect pid}"
      send pid, {:event, ev, state.config}
    end)

    {:noreply, state}
  end

  def handle_info({:event, ev = %SensorEv{}}, state) do
    Logger.debug "Received event #{inspect ev} from one of our sensors"
    send state.receiver, ev
    maybe_partition_alarm(ev, state)
    {:noreply, state}
  end

  def handle_call({:arm, mode}, _from, state) do
    #@arm_modes ["ARM", "ARMSTAY", "ARMSTAYIMMEDIATE"]
    #@disarm_modes ["DISARM"]
    {res, state} = case mode do
      "ARM" ->
        Logger.info("Arming")
        arm_all(state.sensors, state.config)
        config = %PartitionModel{state.config | armed: "ARM"}
        {:ok, %{state | config: config}}
      x ->
        Logger.error("This should not happen, invalid arming #{inspect x}")
        {:error, state}
    end
    {:reply, res, state}
  end

  def handle_call({:disarm, mode}, _from, state) do
    {res, state} = case mode do
      "DISARM" ->
        Logger.info("Disarming")
        disarm_all(state.sensors)
        config = %PartitionModel{state.config | armed: "DISARM"}
        {:ok, %{state | config: config}}
      x ->
        Logger.error("This should not happen, invalid disarm #{inspect x}")
        {:error, state}
    end
    {:reply, res, state}
  end

  def handle_call({:count_sensors}, _from, state) do
    res = Enum.count(state.sensors)
    {:reply, res, state}
  end

  def handle_call({:arming_status}, _from, state) do
    res = state.config.armed
    {:reply, res, state}
  end

  def handle_call({:entry_delay?}, _from, state) do
    res = case state.config.entry_delay do
      nil -> 0
      v -> v
    end
    {:reply, res, state}
  end

  def handle_call({:exit_delay?}, _from, state) do
    res = case state.config.exit_delay do
      nil -> 0
      v -> v
    end
    {:reply, res, state}
  end

  defp maybe_partition_alarm(ev = %SensorEv{}, state) do
    case generate_part_ev?(ev, state) do
      true ->
        ev = %PartitionEv{type: ev.type, name: state.config.name}
        Process.send(state.receiver, ev, [])
      _ -> nil
    end
  end

  defp generate_part_ev?(_ev = %SensorEv{urgent: true}, _state) do
    true
  end

  defp generate_part_ev?(_ev = %SensorEv{urgent: false}, state) do
    case state.config.armed in @arm_modes do
      true -> true
      _ -> false
    end
  end

  defp arm_all(sensors, partition) do
    sensors
    |> Enum.each(fn(sensor) ->
      sensor
      |> GenServer.call({:arm, partition.exit_delay})
    end)
  end

  defp disarm_all(sensors) do
    sensors
    |> Enum.each(fn(sensor) ->
      sensor
      |> GenServer.call({:disarm})
    end)
  end

end
