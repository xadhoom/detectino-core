defmodule DtCore.Sensor.Worker do
  @moduledoc """
  Worker for sensor.
  Handles all the logic when it's values changes
  (which is reported with an event from the DtBus app)
  """
  use GenServer

  require Logger
  alias DtCore.Sensor.Utils
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv

  #
  # Client APIs
  #
  def start_link({config = %SensorModel{}, partition = %PartitionModel{},
    receiver}) do
    {:ok, name} = Utils.sensor_server_name(config, partition)
    GenServer.start_link(__MODULE__, {config, receiver}, name: name)
  end

  def alarm_status({config = %SensorModel{}, partition = %PartitionModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config, partition)
    GenServer.call(name, {:alarm_status?})
  end

  def armed?({config = %SensorModel{}, partition = %PartitionModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config, partition)
    GenServer.call(name, {:armed?})
  end

  #
  # GenServer callbacks
  #
  def init({config, receiver}) do
    Logger.info "Starting Sensor Worker with addr #{config.address} " <>
      "and port #{config.port}"
    state = %{
      config: config,
      original_config: config,
      receiver: receiver,
      armed: false,
      cur_ev: %SensorEv{
        type: :standby, address: config.address, port: config.port
      },
      status: :standby
    }
    {:ok, state}
  end

  def handle_info({:event, ev = %Event{}, partition = %PartitionModel{}}, state) do
    config = state.config
    newstate = case config.enabled do
      false ->
        Logger.debug("Ignoring event from server  cause I'm not online")
        state
      true ->
        if ev.address == config.address and ev.port == config.port do
          Logger.debug("Got event from server")
          event = do_receive_event(ev, partition, state)
          state = sensor_state(event, state)
          :ok = Process.send(state.receiver, {:start, event}, [])
          state
        else
          state
        end
      _ ->
        Logger.debug("Uh? Cannot get enabled status: #{inspect ev}")
        state
    end
    {:noreply, newstate}
  end

  def handle_info({:reset_entry}, state) do
    Logger.info("Resetting Entry Delay")
    config = %SensorModel{state.config | entry_delay: false}
    state = %{state | config: config}
    {:noreply, state}
  end

  def handle_info({:reset_exit}, state) do
    Logger.info("Resetting Exit Delay")
    config = %SensorModel{state.config | exit_delay: false}
    state = %{state | config: config}
    {:noreply, state}
  end

  def handle_call({:internal?}, _from, state) do
    {:reply, state.config.internal, state}
  end

  def handle_call({:armed?}, _from, state) do
    {:reply, state.armed, state}
  end

  def handle_call({:alarm_status?}, _from, state) do
    {:reply, state.status, state}
  end

  def handle_call({:arm, delay}, _from, state) do
    Logger.debug("Arming sensor")
    state = reset_config(state)
    state
    |> zone_exit_delay(delay)
    |> will_reset_delay(:exit)

    {:reply, :ok, %{state | armed: true}}
  end

  def handle_call({:disarm}, _from, state) do
    Logger.debug("Disarming sensor")
    state = reset_config(state)
    config = state.config

    ev = build_ev_type(:standby, config.address, config.port)
    state = sensor_state(ev, state)
    :ok = Process.send(state.receiver, {:start, ev}, [])
    {:reply, :ok, %{state | armed: false}}
  end

  defp sensor_state(ev, state) do
    status = case ev.type do
      :reading -> :standby
      :standby -> :standby
      :tamper -> :tamper
      :fault -> :fault
      :short -> :tamper
      :alarm -> :alarm
    end
    :ok = Process.send(state.receiver, {:stop, state.cur_ev}, [])
    %{state | cur_ev: ev, status: status}
  end

  defp will_reset_delay(delay, delay_t) do
    delay = case delay do
      nil -> 0
      v when is_integer v  -> v
      unk ->
        Logger.error "Got invalid delay value #{inspect unk}"
        0
    end
    case delay_t do
      :entry ->
        Process.send_after(self(), {:reset_entry}, delay * 1000)
      :exit ->
        Process.send_after(self(), {:reset_exit}, delay * 1000)
    end
  end

  defp zone_entry_delay(state, delay) do
    case state.config.entry_delay do
      true -> delay
      _ -> 0
    end
  end

  defp zone_exit_delay(state, delay) do
    case state.config.exit_delay do
      true -> delay
      _ -> 0
    end
  end

  @doc false
  defp do_receive_event(ev = %Event{}, partition = %PartitionModel{}, state) do
    case state.armed do
      v when v == "DISARM" or v == false ->
        case state.config.full24h do
          true ->
            process_inarm(ev, partition, state)
          _ ->
            process_indisarm(ev, partition, state)
        end
      v when v == "ARM" or v == true ->
        process_inarm(ev, partition, state)
    end
  end

  defp process_indisarm(ev, _partition, state) do
    sensor_ev = process_event(ev, state)
    %SensorEv{sensor_ev | type: :reading}

    case sensor_ev.type do
      :alarm ->
          %SensorEv{sensor_ev | type: :reading}
      _ -> sensor_ev
    end
  end

  defp process_inarm(ev, partition, state) do
    urgent = urgent?(state.config)
    p_entry = compute_entry_delay(partition, urgent, state)
    p_exit = compute_exit_delay(partition, urgent, state)

    sensor_ev = process_event(ev, state)

    case exit_delay?(ev, urgent, state) do
      false ->
        inarm_nodelay({ev, sensor_ev, partition, p_entry, urgent, state})
      true ->
        inarm_delay({ev, sensor_ev, partition, p_exit})
      _ ->
        %SensorEv{sensor_ev | delayed: false, urgent: urgent}
    end
  end

  defp compute_exit_delay(partition, urgent, state) do
    delay = case partition.exit_delay do
      d when is_integer(d) and not urgent -> d
      _ -> 0
    end
    zone_exit_delay(state, delay)
  end

  defp compute_entry_delay(partition, urgent, state) do
    delay = case partition.entry_delay do
      d when is_integer(d) and not urgent -> d
      _ -> 0
    end
    zone_entry_delay(state, delay)
  end

  def inarm_delay({ev, sensor_ev, partition, p_exit}) do
    Logger.debug "scheduling delayed exit alarm"
    delay = p_exit * 1000
    ev = %Event{ev | delayed: true}
    _timer = Process.send_after(self(), {:event, ev, partition},
      delay)
    %SensorEv{sensor_ev | delayed: true}
  end

  def inarm_nodelay({ev, sensor_ev, partition, p_entry, urgent, state}) do
    delay = case ev_type_is_delayed?(sensor_ev) do
      true ->
        p_entry * 1000
      _ ->
        Logger.debug("Event #{inspect sensor_ev} " <>
          "not delayed because is not an alarm")
        0
    end
    case delay do
      0 ->
        %SensorEv{sensor_ev | delayed: false, urgent: urgent}
      _ ->
        ev = %Event{ev | delayed: true}
        _timer = Process.send_after(self(), {:event, ev, partition},
          delay)
        maybe_start_entry_timer(state, p_entry)
        %SensorEv{sensor_ev | delayed: true}
    end
  end

  defp ev_type_is_delayed?(ev) do
    case ev.type do
      :alarm -> true
      _ -> false
    end
  end

  defp exit_delay?(ev, urgent, state) do
    case ev.delayed do
      false when not urgent ->
        state.config.exit_delay
      false when urgent ->
        false
      true ->
        Logger.error("I should not be there!")
        nil
    end
  end

  defp urgent?(sensor) do
    case sensor.full24h do
      true ->
        true
      _ ->
        false
    end
  end

  def maybe_start_entry_timer(state, entry_delay) do
    case state.config.exit_delay do
      true ->
        Logger.info "Still in exit delay, not resetting entry"
      v when is_nil(v) or v == false ->
        state
        |> zone_entry_delay(entry_delay)
        |> will_reset_delay(:entry)
    end
  end

  defp process_event(%Event{address: a, port: p, value: v}, _state) when is_nil(a) or is_nil(p) or is_nil(v) do
    :error
  end

  defp process_event(ev = %Event{}, state) do
    case state.config.balance do
      "NC" -> nc(ev, state)
      "NO" -> no(ev, state)
      "EOL" -> eol(ev, state)
      "DEOL" -> deol(ev, state)
      "TEOL" -> teol(ev, state)
      _ -> :error
    end
  end

  defp nc(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    case ev.value do
      v when (v < th1) ->
        build_ev_type(:standby, ev.address, ev.port)
      _ ->
        build_ev_type(:alarm, ev.address, ev.port)
    end
  end

  defp no(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    case ev.value do
      v when (v < th1) ->
        build_ev_type(:alarm, ev.address, ev.port)
      _ ->
        build_ev_type(:standby, ev.address, ev.port)
    end
  end

  defp eol(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    th2 = me.th2
    case ev.value do
      v when (v < th1) ->
        build_ev_type(:short, ev.address, ev.port)
      v when (v < th2) ->
        build_ev_type(:standby, ev.address, ev.port)
      _ ->
        build_ev_type(:alarm, ev.address, ev.port)
    end
  end

  defp deol(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    th2 = me.th2
    th3 = me.th3
    case ev.value do
      v when (v < th1) ->
        build_ev_type(:short, ev.address, ev.port)
      v when (v < th2) ->
        build_ev_type(:standby, ev.address, ev.port)
      v when (v < th3) ->
        build_ev_type(:alarm, ev.address, ev.port)
      _ ->
        build_ev_type(:tamper, ev.address, ev.port)
    end
  end

  defp teol(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    th2 = me.th2
    th3 = me.th3
    th4 = me.th4
    case ev.value do
      v when (v < th1) ->
        build_ev_type(:short, ev.address, ev.port)
      v when (v < th2) ->
        build_ev_type(:standby, ev.address, ev.port)
      v when (v < th3) ->
        build_ev_type(:alarm, ev.address, ev.port)
      v when (v < th4) ->
        build_ev_type(:fault, ev.address, ev.port)
      _ ->
        build_ev_type(:tamper, ev.address, ev.port)
    end
  end

  defp build_ev_type(type, address, port) do
    %SensorEv{
      type: type,
      address: address,
      port: port
    }
  end

  defp reset_config(state) do
    Logger.debug("Resetting sensor config")
    %{state | config: state.original_config}
  end

end
