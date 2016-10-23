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
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv

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
    send self(), :start
    {:ok, state}
  end

  def handle_info(:start, state) do
    parts_alive? = state.config.partitions
    |> Enum.reduce(true, fn(part, _acc) ->
      case Partition.alive?(part) do
        true -> true
        _ -> false
      end
    end)
    case parts_alive? do
      true ->
        :ok = process_delays(state)
        {:noreply, state}
      _ ->
        {:stop, :dead_partitions, state}
    end
  end

  def handle_info({:event, ev = %Event{}}, state) do
    case state.config.enabled do
      false -> Logger.debug("Ignoring event from server  cause I'm not online")
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
    tmp = case Enum.empty?(state.config.partitions) do
      true -> 0
      false ->
        state.config.partitions
        |> Enum.min_by(fn(item) ->
          item.entry_delay
        end)
    end
    entry_delay = case tmp do
      %PartitionModel{entry_delay: v} -> v
      _ -> 0
    end

    tmp = case Enum.empty?(state.config.partitions) do
      true -> 0
      false ->
        state.config.partitions
        |> Enum.min_by(fn(item) ->
          item.exit_delay
        end)
    end
    exit_delay = case tmp do
      %PartitionModel{exit_delay: v} -> v
      _ -> 0
    end

    # if we have many partitions, one may been just armed
    # while the other is disarmed, depending on the scenario
    # so just get the first and we'll use it to determine
    # if we need to use entry or exit delay
    is_entry = state.config.partitions
    |> Enum.at(0)
    |> Partition.entry?

    case is_entry do
      true ->
        state
        |> zone_entry_delay(entry_delay)
        |> will_reset_delay(:entry)
      false ->
        state
        |> zone_exit_delay(exit_delay)
        |> will_reset_delay(:exit)
      nil -> Logger.debug("Partition delay not set")
        will_reset_delay(0, :entry)
    end
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
    parts
    |> Enum.reduce([], fn(partition, acc) ->
      armed = partition
      |> Partition.arming_status

      ret = case armed do
        "DISARM" ->
          case state.config.full24h do
            true ->
              process_inarm(ev, partition, state)
            _ ->
              process_indisarm(ev, partition, state)
          end
        "ARM" ->
          process_inarm(ev, partition, state)
      end
      Enum.concat(acc, [ret])
    end)
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

end
