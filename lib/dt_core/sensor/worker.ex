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
  alias DtCore.Sensor.Worker
  alias DtLib.Delayer

  @type t :: %__MODULE__{original_config: %SensorModel{},
    receiver: pid,
    armed: boolean,
    cur_ev: %SensorEv{} | nil, # last sent %SensorEv{}
    last_ev: %Event{} | nil, # last received %Event{}
    status: atom,
    myname: String.t,
    exit_timers: pid,
    entry_timers: pid,
    exit_t_running: boolean}
  defstruct config: nil,
    original_config: nil,
    receiver: nil,
    armed: false,
    cur_ev: nil, # last sent %SensorEv{}
    last_ev: nil, # last received %Event{}
    status: nil,
    myname: nil,
    exit_timers: nil,
    entry_timers: nil,
    exit_t_running: false

  #
  # Client APIs
  #
  def start_link({config = %SensorModel{}, partition = %PartitionModel{},
    receiver}) do
    {:ok, name} = Utils.sensor_server_name(config, partition)
    GenServer.start_link(__MODULE__, {config, receiver, name}, name: name)
  end

  def alarm_status({config = %SensorModel{}, partition = %PartitionModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config, partition)
    GenServer.call(name, {:alarm_status?})
  end

  def armed?({config = %SensorModel{}, partition = %PartitionModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config, partition)
    GenServer.call(name, {:armed?})
  end

  @doc false
  def expire_timer({:exit_timer, name}) do
    GenServer.call(name, {:reset_exit})
  end

  #
  # GenServer callbacks
  #
  @spec init({%SensorModel{}, pid, String.t}) :: {:ok, Worker.t}
  def init({config, receiver, name}) do
    Logger.info "Starting Sensor Worker with addr #{config.address} " <>
      "and port #{config.port}"
    {:ok, entry_t_pid} = Delayer.start_link()
    {:ok, exit_t_pid} = Delayer.start_link()
    state = %Worker{
      config: config,
      original_config: config,
      receiver: receiver,
      armed: false,
      cur_ev: %SensorEv{
        type: :standby, address: config.address, port: config.port
      },
      last_ev: nil,
      status: :standby,
      myname: name,
      exit_timers: exit_t_pid,
      entry_timers: entry_t_pid
    }
    Etimer.start_link(state.myname)
    {:ok, state}
  end

  @doc false
  def handle_info({:flush, :entry}, state) do
    # used only for tests
    {:ok, events} = Delayer.stop_all(state.entry_timers)
    Enum.each(events, fn(ev) ->
      send self(), ev
    end)
    {:noreply, state}
  end

  @doc false
  def handle_info({:flush, :exit}, state) do
    # used only for tests
    {:ok, events} = Delayer.stop_all(state.exit_timers)
    Enum.each(events, fn(ev) ->
      send self(), ev
    end)
    {:noreply, state}
  end

  @spec handle_info({:event, %Event{}, %PartitionModel{}},
    Worker.t) :: {:noreply, Worker.t}
  def handle_info({:event, ev = %Event{}, partition = %PartitionModel{}},
    state) do

    cmp_ev = ev |> Map.from_struct |> Map.drop([:delayed])
    cmp_last_ev = case state.last_ev do
      nil -> nil
      v -> v |> Map.from_struct |> Map.drop([:delayed])
    end

    newstate = case cmp_last_ev do
      ^cmp_ev -> state
      _ -> receive_event({:event, ev, partition}, state)
    end

    {:noreply, newstate}
  end

  @spec handle_info({:delayed_event, %Event{}, %PartitionModel{}},
    Worker.t) :: {:noreply, Worker.t}
  def handle_info({:delayed_event, ev = %Event{}, partition = %PartitionModel{}},
    state) do
    newstate = case state.last_ev do
      ^ev -> state
      _ -> receive_event({:event, ev, partition}, state)
    end

    {:noreply, newstate}
  end

  def handle_call({:reset_exit}, _from, state) do
    Logger.info("Resetting Exit Delay")
    config = %SensorModel{state.config | exit_delay: false}
    state = %Worker{state | config: config, exit_t_running: false}
    {:reply, :ok, state}
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

  @spec handle_call({:arm, nil | 0 | false}, any, Worker.t) :: {:reply, :ok, Worker.t}
  def handle_call({:arm, v}, _from, state)
      when is_nil(v) or v == 0 or v == false do
    Logger.debug("Arming sensor now!")
    state = reset_config(state)

    config = %SensorModel{state.config | exit_delay: false}
    state = %Worker{state | config: config}

    {:reply, :ok, %Worker{state | armed: true}}
  end

  @spec handle_call({:arm, pos_integer}, any, Worker.t) :: {:reply, :ok, Worker.t}
  def handle_call({:arm, delay}, _from, state)
      when is_number(delay) and delay > 0 do
    Logger.debug("Arming sensor")

    state = reset_config(state)

    state = case zone_exit_delay(state, delay) do
      0 ->
        config = %SensorModel{state.config | exit_delay: false}
        %Worker{state | config: config}
      d ->
        will_reset_delay(d, :exit, state)
    end

    {:reply, :ok, %Worker{state | armed: true}}
  end

  def handle_call({:disarm}, _from, state) do
    Logger.debug("Disarming sensor")
    {:ok, _} = Delayer.stop_all(state.exit_timers)
    {:ok, _} = Delayer.stop_all(state.entry_timers)
    state = reset_config(state)

    state = case state.last_ev do
      nil ->
        state
      last_ev ->
        # processing again last event in disarm state
        # in order to cancel any previous trigger
        {ev, state} = process_indisarm(last_ev, nil, state)
        status = sensor_state(ev, state)

        # and send it to our receiver
        :ok = Process.send(state.receiver, {:stop, state.cur_ev}, [])
        :ok = Process.send(state.receiver, {:start, ev}, [])

        %Worker{state | cur_ev: ev, status: status}
    end

    {:reply, :ok, %Worker{state | armed: false}}
  end

  defp sensor_state(ev, _state) do
    case ev.type do
      :reading -> :standby
      :standby -> :standby
      :tamper -> :tamper
      :fault -> :fault
      :short -> :tamper
      :alarm -> :alarm
    end
  end

  defp will_reset_delay(delay, :exit, state) do
      :ok = start_exit_timer(delay, state)
      %{state | exit_t_running: true}
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

  @spec receive_event({:event, %Event{}, %PartitionModel{}},
    Worker.t) :: Worker.t
  defp receive_event({:event, ev = %Event{}, partition = %PartitionModel{}},
    state) do
    config = state.config
    case config.enabled do
      false ->
        Logger.debug("Ignoring event from server  cause I'm not online")
        state
      true ->
        if ev.address == config.address and ev.port == config.port do
          Logger.debug("Got event from server")
          {event, state} = do_receive_event(ev, partition, state)
          status = sensor_state(event, state)
          :ok = Process.send(state.receiver, {:stop, state.cur_ev}, [])
          :ok = Process.send(state.receiver, {:start, event}, [])
          %Worker{state | last_ev: ev, cur_ev: event, status: status}
        else
          state
        end
      _ ->
        Logger.debug fn -> "Uh? Cannot get enabled status: #{inspect ev}" end
        state
    end
  end

  @spec do_receive_event(%Event{}, %PartitionModel{},
    Worker.t) :: {%SensorEv{}, Worker.t}
  defp do_receive_event(ev = %Event{}, partition = %PartitionModel{}, state) do
    case state.armed do
      v when v == "DISARM" or v == false ->
        case urgent?(state.config) do
          true ->
            process_inarm(ev, partition, state)
          _ ->
            process_indisarm(ev, partition, state)
        end
      v when v == "ARM" or v == true ->
        process_inarm(ev, partition, state)
    end
  end

  @spec process_indisarm(%Event{}, any(),
    Worker.t) :: {%SensorEv{}, Worker.t}
  defp process_indisarm(ev = %Event{}, _partition, state) do
    sensor_ev = process_event(ev, state)

    case sensor_ev.type do
      :alarm ->
          {%SensorEv{sensor_ev | type: :reading}, state}
      _ -> {sensor_ev, state}
    end
  end

  @spec process_inarm(%Event{}, %PartitionModel{},
    Worker.t) :: {%SensorEv{}, Worker.t}
  defp process_inarm(ev, partition, state) do
    urgent = urgent?(state.config)
    p_entry = compute_entry_delay(partition, urgent, state)
    p_exit = compute_exit_delay(partition, urgent, state)

    sensor_ev = process_event(ev, state)

    # check if exit delay applies
    is_exit_delayed? = case ev_type_is_delayed?(sensor_ev) do
      true -> exit_delay?(ev, urgent, state)
      false -> false
    end

    # cleanup queued alarms if a tamper kicks in
    case priority_event?(sensor_ev) do
      false -> nil
      true ->
        case exit_delay?(ev, urgent, state) do
          true ->
            {:ok, _} = Delayer.stop_all(state.exit_timers)
          false ->
            {:ok, _} = Delayer.stop_all(state.entry_timers)
        end
    end

    case is_exit_delayed? do
      false ->
        # here we may have or not an entry delay
        case ev_type_is_delayed_on_entry?(sensor_ev, state) do
          true ->
            inarm_entry_delay({ev, sensor_ev, partition, p_entry, urgent}, state)
          false ->
            inarm_entry_delay({ev, sensor_ev, partition, 0, urgent}, state)
        end
      true ->
        inarm_exit_delay({ev, sensor_ev, partition, p_exit}, state)
      _ ->
        {%SensorEv{sensor_ev | delayed: false, urgent: urgent}, state}
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

  @spec inarm_exit_delay({%Event{}, %SensorEv{}, %PartitionModel{},
    non_neg_integer}, Worker.t) :: {%SensorEv{}, Worker.t}
  defp inarm_exit_delay({ev, sensor_ev, partition, p_exit}, state) do
    Logger.debug "scheduling delayed exit alarm"
    delay = p_exit * 1000
    ev = %Event{ev | delayed: true}
    # XXX this one should be cancelled if disarmed, or better call {:flush, :exit}
    Delayer.put(state.exit_timers, {:delayed_event, ev, partition}, delay)
    {%SensorEv{sensor_ev | delayed: true}, state}
  end

  @spec inarm_entry_delay({%Event{}, %SensorEv{}, %PartitionModel{},
    non_neg_integer, boolean}, Worker.t) :: {%SensorEv{}, Worker.t}
  defp inarm_entry_delay({ev, sensor_ev, partition, p_entry, urgent}, state) do
    # this one handles the entry delay
    delay = p_entry * 1000
    case delay do
      0 ->
        {%SensorEv{sensor_ev | delayed: false, urgent: urgent}, state}
      _ ->
        ev = %Event{ev | delayed: true}
        # XXX this one should be cancelled if disarmed or better call {:flush, :entry}
        Delayer.put(state.entry_timers, {:delayed_event, ev, partition}, delay)
        {%SensorEv{sensor_ev | delayed: true}, state}
    end
  end

  defp ev_type_is_delayed?(ev) do
    case ev.type do
      :alarm -> true
      _ -> false
    end
  end

  defp ev_type_is_delayed_on_entry?(ev, state) do
    ev
    |> ev_type_is_delayed?
    |> run_entry_delay?(state.exit_t_running, state.config.exit_delay, state.config.entry_delay)
  end

  @spec run_entry_delay?(boolean, boolean, boolean, boolean) :: boolean
  # defp run_entry_delay?(is_delayed_ev, t_exit_running, exit_delay, entry_delay)
  defp run_entry_delay?(false, _, _, _) do false end
  defp run_entry_delay?(true, true, false, _) do false end
  defp run_entry_delay?(true, false, _, true) do true end
  defp run_entry_delay?(true, false, _, false) do false end

  defp priority_event?(ev) do
    case ev.type do
      v when v in [:fault, :short, :tamper] -> true
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
    %Worker{state | config: state.original_config}
  end

  defp start_exit_timer(delay, state) do
    delay = case Etimer.stop_timer(state.myname, :exit_timer) do
      {:ok, remaing_time} -> remaing_time
      :not_running -> delay * 1000
    end
    Etimer.start_timer(state.myname, :exit_timer, delay,
      {Worker, :expire_timer, [{:exit_timer, state.myname}]})
  end

end
