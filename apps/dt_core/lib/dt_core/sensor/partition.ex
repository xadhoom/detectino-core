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
      send pid, {:event, ev}
    end)

    {:noreply, state}
  end

  def handle_info({:event, ev = %SensorEv{}}, state) do
    Logger.debug "Received event #{inspect ev} from one of our sensors"

    send state.receiver, {:event, ev}

    {:noreply, state}
  end

  def handle_call({:arm, mode}, _from, state) do
    #@arm_modes ["ARM", "ARMSTAY", "ARMSTAYIMMEDIATE"]
    #@disarm_modes ["DISARM"]
    res = case mode do
      "ARM" ->
        Logger.info("Arming")
        arm_all(state.sensors)
      x ->
        Logger.error("This should not happen, invalid arming #{inspect x}")
        :error
    end
    {:reply, res, state}
  end

  def handle_call({:disarm, mode}, _from, state) do
    res = case mode do
      "DISARM" ->
        Logger.info("Disarming")
        disarm_all(state.sensors)
      x ->
        Logger.error("This should not happen, invalid disarm #{inspect x}")
        :error
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

  defp arm_all(sensors) do
    sensors
    |> Enum.each(fn(sensor) ->
      sensor
      |> GenServer.call({:arm})
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
