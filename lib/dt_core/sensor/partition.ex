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
  alias DtCore.ArmEv
  alias DtCore.ExitTimerEv
  alias DtCore.SensorEv
  alias DtCore.PartitionEv
  alias DtCore.EventBridge

  @arm_modes ["ARM", "ARMSTAY", "ARMSTAYIMMEDIATE"]
  @disarm_modes ["DISARM"]
  @statuses [:standby, :alarm, :tamper]

  def start_link({config = %PartitionModel{}, cache}) do
    {:ok, name} = Utils.partition_server_name(config)
    GenServer.start_link(__MODULE__, {config, cache}, name: name)
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

  def alarm_status(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:alarm_status?})
  end

  def alarm_status(server) when is_pid(server) do
    GenServer.call(server, {:alarm_status?})
  end

  #
  # GenServer Callbacks
  #
  def init({config, cache}) do
    Logger.debug fn -> "Starting partition worker with " <>
      "#{inspect config} config" end
    state = %{
      config: config,
      sensors: [],
      cache: cache,
      status: :standby,
      last: nil,
      t_exit: nil
    }
    newstate = state
    |> reload_cache
    |> dostart
    {:ok, newstate}
  end

  def handle_info({:event, ev = %Event{}}, state) do
    Logger.debug fn -> "Received event #{inspect ev} from server" end

    state.sensors
    |> Enum.each(fn(pid) ->
      Logger.debug fn ->
        "Sending event #{inspect ev} to sensor #{inspect pid}"
      end
      send pid, {:event, ev, state.config}
    end)

    {:noreply, state}
  end

  def handle_info(msg = {op, _ev = %SensorEv{}}, state) when op == :start
    or op == :stop do
    Logger.debug fn ->
      "Received event #{inspect msg} from one of our sensors"
    end
    msg |> dispatch

    last = case maybe_partition_alarm(msg, state) do
      {:start, ev} -> {:start, ev}
      {:stop, ev} -> {:stop, ev}
      _ -> state.last
    end

    status = query_alarm_status(state.sensors)
    {:noreply, %{state | status: status, last: last}}
  end

  def handle_info({:reset_exit}, state) do
    state = notify_exit_timer_stop(state)
    {:noreply, state}
  end

  def handle_call({:arm, mode}, _from, state) do
    all_idle = Enum.all?(state.sensors, fn(sensor) ->
      :standby == Worker.alarm_status(sensor)
    end)

    with true <- all_idle do
      {res, state} = do_arm(state, mode)
      true = save_state(state)
      {:reply, res, state}
    else
      _ -> {:reply, {:error, :tripped}, state}
    end
  end

  def handle_call({:disarm, mode}, _from, state) do
    {res, state} = case mode do
      "DISARM" ->
        Logger.info("Disarming")
        disarm_all(state.sensors)

        case state.last do
          {_, ev = %PartitionEv{}} ->
            Logger.debug("Dispatching stop for partition alarm")
            dispatch({:stop, ev})
          _ -> nil
        end

        config = %PartitionModel{state.config | armed: "DISARM"}
        {:ok, %{state | config: config}}
      x ->
        Logger.error fn ->
          "This should not happen, invalid disarm #{inspect x}"
        end
        {:error, state}
    end
    state = notify_disarm_operation(state)
    true = save_state(state)
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

  def handle_call({:armed?}, _from, state) do
    res = state.config.armed in @arm_modes
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

  def handle_call({:alarm_status?}, _from, state) do
    {:reply, state.status, state}
  end

  defp reload_cache(state) do
    {:ok, name} = Utils.partition_server_name(state.config)
    state = case :ets.lookup(state.cache, name) do
      [{_key, value}] ->
        Logger.info "Reloaded cached state"
        %{state | config: value}
      _ ->
        Logger.info "No state to reload"
        state
    end
    true = save_state(state)
    state
  end

  defp dostart(state) do
    sensors_pids = state.config.sensors
    |> Enum.reduce([], fn(sensor, acc) ->
      case Worker.start_link({sensor, state.config, self()}) do
        {:ok, pid} ->
          acc ++ [pid]
        {:error, what} ->
          Logger.error fn -> "Cannot start Sensor, #{inspect what}" end
          acc
      end
    end)
    state = %{state | sensors: sensors_pids}
    {_, newstate} = do_arm(state, state.config.armed)
    newstate
  end

  defp save_state(state) do
    {:ok, name} = Utils.partition_server_name(state.config)
    true = :ets.insert(state.cache, {name, state.config})
  end

  defp do_arm(state, "ARM") do
    Logger.info("Arming")
    arm_all(state.sensors, state.config)
    state = notify_arm_operation(state, :immediate)
    config = %PartitionModel{state.config | armed: "ARM"}
    {:ok, %{state | config: config}}
  end

  defp do_arm(state, "ARMSTAY") do
    Logger.info("Partial Arming")
    arm_partial(state.sensors, state.config, false)
    state = notify_arm_operation(state, :partial)
    config = %PartitionModel{state.config | armed: "ARMSTAY"}
    {:ok, %{state | config: config}}
  end

  defp do_arm(state, "ARMSTAYIMMEDIATE") do
    Logger.info("Partial Arming, immediate mode")
    arm_partial(state.sensors, state.config, true)
    state = notify_arm_operation(state, :partial_immediate)
    config = %PartitionModel{state.config | armed: "ARMSTAYIMMEDIATE"}
    {:ok, %{state | config: config}}
  end

  defp do_arm(state, "DISARM") do
    state = notify_disarm_operation(state)
    {:ok, state}
  end

  defp do_arm(state, nil) do
    {:ok, state}
  end

  defp do_arm(state, v) do
    Logger.error fn ->
      "This should not happen, invalid arming #{inspect v}"
    end
    {:error, state}
  end

  defp notify_arm_operation(state, :partial) do
    dispatch({:start, %ArmEv{name: state.config.name, partial: true}})
    notify_exit_timer_start(state)
  end

  defp notify_arm_operation(state, :partial_immediate) do
    dispatch({:start, %ArmEv{name: state.config.name, partial: true}})
    notify_exit_timer_start(state, 0)
  end

  defp notify_arm_operation(state, :immediate) do
    dispatch({:start, %ArmEv{name: state.config.name, partial: false}})
    notify_exit_timer_start(state)
  end

  defp notify_disarm_operation(state) do
    dispatch({:stop, %ArmEv{name: state.config.name, partial: nil}})
    notify_exit_timer_stop(state)
  end

  defp notify_exit_timer_start(state, force_delay \\ nil)

  defp notify_exit_timer_start(state = %{config: %{exit_delay: nil}}, _) do
    state
  end

  defp notify_exit_timer_start(state, force_delay) do
    dispatch({:start, %ExitTimerEv{name: state.config.name}})

    delay = case force_delay do
      d when is_number(d) -> d
      _ -> state.config.exit_delay
    end

    tref = Process.send_after(self(),
      {:reset_exit}, round(delay * 1000))
    %{state | t_exit: tref}
  end

  defp notify_exit_timer_stop(state = %{t_exit: nil}) do
    state
  end

  defp notify_exit_timer_stop(state) do
    Process.cancel_timer(state.t_exit)
    dispatch({:stop, %ExitTimerEv{name: state.config.name}})
    %{state | t_exit: nil}
  end

  defp dispatch(msg = {_op, ev = %SensorEv{}}) do
    key = %{source: :sensor, address: ev.address, port: ev.port, type: ev.type}
    EventBridge.dispatch(key, msg)
  end

  defp dispatch(msg = {_op, ev = %PartitionEv{}}) do
    key = %{source: :partition, name: ev.name, type: ev.type}
    EventBridge.dispatch(key, msg)
  end

  defp dispatch(msg = {_op, ev = %ArmEv{}}) do
    key = %{source: :partition, name: ev.name}
    EventBridge.dispatch(key, msg)
  end

  defp dispatch(msg = {_op, ev = %ExitTimerEv{}}) do
    key = %{source: :partition, name: ev.name}
    EventBridge.dispatch(key, msg)
  end

  # partition alarm must start on single sensor event,
  # but stop only if all sensors are idle
  defp maybe_partition_alarm({op, ev = %SensorEv{}}, state) do
    case generate_part_ev?(ev, state) do
      true ->
        {op, ev}
        |> build_part_ev(state)
        |> maybe_dispatch_pev(state)
      _ -> nil
    end
  end

  defp maybe_dispatch_pev(p_ev, state) do
    case p_ev do
      nil -> nil
      ev ->
        if ev == state.last do
          Logger.debug "skipping already sent partition ev"
        else
          Logger.debug fn -> "Sending partion event #{inspect ev}" end
          ev |> dispatch
        end
        ev
    end
  end

  defp build_part_ev({op, ev = %SensorEv{}}, state) do
    status = state.status
    case op do
      :start ->
        {op, %PartitionEv{type: ev.type,
          delayed: ev.delayed, name: state.config.name}}
      :stop ->
        case query_alarm_status(state.sensors) do
          :standby ->
            {op, %PartitionEv{type: ev.type,
              delayed: ev.delayed, name: state.config.name}}
          x when x in @statuses and x != status ->
            {op, %PartitionEv{type: ev.type,
              delayed: ev.delayed, name: state.config.name}}
          x ->
            Logger.info fn ->
              "Not stopping partition alarm due to others: #{x}"
            end
            nil
        end
      x ->
        Logger.error fn -> "Unhandled operation #{inspect x})" end
        nil
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

  defp arm_partial(sensors, partition, immediate) do
    sensors
    |> Enum.each(fn(sensor) ->
      internal? = sensor |> GenServer.call({:internal?})
      case internal? do
        true ->
          Logger.info fn ->
            "Skip arming sensor #{inspect sensor} because internal"
          end
        _ ->
          sensor |> arm_partial_run(partition, immediate)
      end
    end)
  end

  defp arm_partial_run(sensor, partition, immediate) do
    case immediate do
      true ->
        :ok = GenServer.call(sensor, {:arm, partition.exit_delay})
      false ->
        :ok = GenServer.call(sensor, {:arm, 0})
    end
  end

  defp arm_all(sensors, partition) do
    sensors
    |> Enum.each(fn(sensor) ->
      :ok = GenServer.call(sensor, {:arm, partition.exit_delay})
    end)
  end

  defp disarm_all(sensors) do
    sensors
    |> Enum.each(fn(sensor) ->
      sensor
      |> GenServer.call({:disarm})
    end)
  end

  #check if all of our sensors are idle or not
  defp query_alarm_status(sensors) do
    sensors
    |> Enum.reduce_while(:standby, fn(s, _acc) ->
      case GenServer.call(s, {:alarm_status?}) do
        :standby -> {:cont, :standby}
        :alarm -> {:halt, :alarm}
        :tamper -> {:halt, :tamper}
        :fault -> {:halt, :fault}
        :reading -> {:halt, :alarm}
        x ->
          Logger.error fn -> "Unhandled status #{inspect x}" end
          {:halt, :tamper}
      end
    end)
  end

end
