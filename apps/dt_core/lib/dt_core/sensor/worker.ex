defmodule DtCore.Sensor.Worker do
  @moduledoc """
  Worker for sensor.
  Handles all the logic when it's values changes
  (which is reported with an event from the DtBus app)
  """
  use GenServer

  require Logger
  alias DtCore.Sensor.Utils
  alias DtCore.Sensor.Partition
  alias DtWeb.Sensor, as: SensorModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv
  alias DtWeb.Repo

  #
  # Client APIs
  #
  def start_link({config = %SensorModel{}, pid}) do
    {:ok, name} = Utils.sensor_server_name(config)
    GenServer.start_link(__MODULE__, {config, pid}, name: name)
  end

  #
  # GenServer callbacks
  #
  def init({config, pid}) do
    Logger.info "Starting Sensor Worker with addr #{config.address} " <>
      "and port #{config.port}"
    state = %{
      config: config,
      receiver: pid
    } 
    :ok = process_delays(state)
    {:ok, state}
  end

  def handle_info({:event, ev = %Event{}}, state) do
    case state.config.enabled do
      false -> Logger.debug("Got event from server, but I'm not online, ignoring")
      true ->
        Logger.debug("Got event from server")
        events = build_events(ev, state)
        :ok = Process.send(state.receiver, events, []) 
      _ -> Logger.debug("Uh? Cannot get enabled status: #{inspect ev}")
    end
    {:noreply, state}
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

  defp process_delays(state) do
    state.config.partitions 
    |> Enum.each(fn(partition) ->
      is_entry = entry?(partition)
      delay = case is_entry do
        true ->
          zone_entry_delay(state, partition.entry_delay)
          |> will_reset_delay(:entry)
        false ->
          zone_exit_delay(state, partition.exit_delay)
          |> will_reset_delay(:exit)
        nil -> Logger.debug("Partition delay not set")
          will_reset_delay(0, :entry)
      end
    end)
    :ok
  end

  defp will_reset_delay(delay, delay_t) do
    case delay_t do
      :entry ->
        Process.send_after(self, {:reset_entry}, delay * 1000)
      :exit ->
        Process.send_after(self, {:reset_exit}, delay * 1000)
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
  defp build_events(ev = %Event{}, state) do
    parts = state.config.partitions
    events = parts
    |> Enum.reduce([], fn(partition, acc) ->
      armed = partition
      |> Partition.arming_status
      case armed do
        "DISARM" ->
          case state.config.full24h do
            true ->
              acc ++ process_inarm(ev, partition, state)
            _ ->
              acc ++ process_indisarm(ev, partition, state)
          end
        "ARM" -> 
          acc ++ process_inarm(ev, partition, state)
      end
    end)
  end

  defp process_indisarm(ev, partition, state) do
    sensor_ev = process_event(ev, state)
    %SensorEv{sensor_ev | type: :reading}

    case sensor_ev.type do
      :alarm ->
          %SensorEv{sensor_ev | type: :reading}
      _ -> sensor_ev
    end
  end

  defp process_inarm(ev, partition, state) do
    sensor_ev = process_event(ev, state)
    case state.config.entry_delay do
      false -> sensor_ev
      true ->
        delay = partition.entry_delay * 1000
        _timer = Process.send_after(self, {:event, ev},
          delay + 1000)
        %SensorEv{sensor_ev | delayed: true}
    end
  end

  defp entry?(partition) do
    case partition.armed do
      v when v in ["ARM", "ARMSTAY", "ARMSTAYIMMEDIATE"] ->
        case partition.last_armed do
          "DISARM" -> false
          _ -> true
        end
      _ -> false
    end
  end

  defp process_event(%Event{address: a, port: p, value: v}, state) when is_nil(a) or is_nil(p) or is_nil(v) do
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

end
