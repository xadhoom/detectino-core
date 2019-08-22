defmodule DtCore.Monitor.Detector do
  @moduledoc """
  Worker for sensor.
  Handles all the logic when it's values changes
  (which is reported with an event from the DtBus app)
  """
  use GenServer

  alias DtCore.DetectorEntryEv
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.Event
  alias DtCore.EventBridge
  alias DtCore.Monitor.DetectorFsm
  alias DtCore.Monitor.Utils
  alias DtCtx.Monitoring.Sensor, as: SensorModel

  require Logger

  # Internal types

  @typep detector_state :: %__MODULE__{
           config: %SensorModel{},
           fsm: pid,
           listeners: list(pid),
           exit_timeout: non_neg_integer,
           entry_timeout: non_neg_integer
         }
  defstruct config: nil,
            fsm: nil,
            debug: false,
            listeners: [],
            # Setting timeouts to a very high value in order
            # to compare and use the minor one.
            # Maybe we can set to zero and find a better way
            # for proper comparison
            exit_timeout: 100_000,
            entry_timeout: 100_000

  #
  # Client APIs
  #
  def start_link({config = %SensorModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config)
    GenServer.start_link(__MODULE__, {config}, name: name)
  end

  def link({config = %SensorModel{}}) do
    config
    |> Utils.sensor_server_pid()
    |> Process.link()
  end

  def status({config = %SensorModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config)
    GenServer.call(name, :status)
  end

  def status(server) when is_pid(server) do
    GenServer.call(server, :status)
  end

  def arm({config = %SensorModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config)
    GenServer.call(name, :arm)
  end

  def arm(server) when is_pid(server) do
    GenServer.call(server, :arm)
  end

  def arm({config = %SensorModel{}, mode}) when mode in [:stay, :immediate] do
    {:ok, name} = Utils.sensor_server_name(config)
    GenServer.call(name, {:arm, mode})
  end

  def disarm({config = %SensorModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config)
    GenServer.call(name, :disarm)
  end

  def disarm(server) when is_pid(server) do
    GenServer.call(server, :disarm)
  end

  def subscribe(
        {config = %SensorModel{}},
        timeouts = {_entry_timeout, _exit_timeout}
      ) do
    {:ok, name} = Utils.sensor_server_name(config)
    GenServer.call(name, {:subscribe, self(), timeouts})
  end

  def subscribe(server, timeouts = {_entry_timeout, _exit_timeout}) do
    GenServer.call(server, {:subscribe, self(), timeouts})
  end

  #
  # GenServer Callbacks
  #
  @spec init({%SensorModel{}}) :: {:ok, detector_state}
  def init({config}) do
    {:ok, fsm} = DetectorFsm.start_link({config, self()})
    {:ok, %__MODULE__{fsm: fsm, config: config, debug: false}}
  end

  def handle_call(:status, _from, state) do
    status = DetectorFsm.status(state.fsm)
    {:reply, status, state}
  end

  def handle_call({:subscribe, pid, {nil, nil}}, _from, state)
      when is_pid(pid) do
    listeners = [pid | state.listeners]
    Process.monitor(pid)

    {:reply, :ok, %__MODULE__{state | listeners: listeners}}
  end

  def handle_call({:subscribe, pid, {entry_timeout, exit_timeout}}, _from, state)
      when is_pid(pid) and is_number(entry_timeout) and is_number(exit_timeout) do
    listeners = [pid | state.listeners]
    Process.monitor(pid)

    entry_timeout =
      if entry_timeout < state.entry_timeout do
        entry_timeout
      else
        state.entry_timeout
      end

    exit_timeout =
      if exit_timeout < state.exit_timeout do
        exit_timeout
      else
        state.exit_timeout
      end

    {:reply, :ok,
     %__MODULE__{
       state
       | listeners: listeners,
         exit_timeout: exit_timeout,
         entry_timeout: entry_timeout
     }}
  end

  def handle_call(:arm, _from, state) do
    entry_timeout = state.entry_timeout * 1000
    exit_timeout = state.exit_timeout * 1000
    reply = DetectorFsm.arm(state.fsm, {entry_timeout, exit_timeout})
    {:reply, reply, state}
  end

  def handle_call({:arm, :stay}, from, state) do
    # if the sensor is internal, do not arm it in stay mode
    case state.config.internal do
      true -> {:reply, :ok, state}
      false -> handle_call(:arm, from, state)
    end
  end

  def handle_call({:arm, :immediate}, _from, state) do
    # if the sensor is internal, do not arm it in immediate mode,
    # otherwise arm with zero exit delay
    case state.config.internal do
      true ->
        {:reply, :ok, state}

      false ->
        entry_timeout = state.entry_timeout * 1000
        exit_timeout = 0
        reply = DetectorFsm.arm(state.fsm, {entry_timeout, exit_timeout})
        {:reply, reply, state}
    end
  end

  def handle_call(:disarm, _from, state) do
    reply = DetectorFsm.disarm(state.fsm)
    {:reply, reply, state}
  end

  @spec handle_info({:event, %Event{}}, detector_state) :: {:noreply, detector_state}
  def handle_info({:event, ev = %Event{}}, state = %{config: %{enabled: false}}) do
    debug_log(
      fn ->
        "Ignoring event #{inspect(ev)} because I'm disabled"
      end,
      state
    )

    {:noreply, state}
  end

  def handle_info({:event, ev = %Event{}}, state) do
    case process_event(ev, state) do
      :not_me ->
        nil

      # Logger.debug fn() -> "Wrong event address/port #{inspect ev}" end
      :error ->
        Logger.warn(fn -> "Cannot decode event #{inspect(ev)}" end)

      v ->
        debug_log(fn -> "Processing event #{inspect(ev)}" end, state)
        DetectorFsm.event(state.fsm, v)
    end

    {:noreply, state}
  end

  def handle_info(msg = {:start, ev = %DetectorEv{}}, state) do
    Enum.each(state.listeners, fn listener ->
      send(listener, {:start, ev})
    end)

    key = %{source: :sensor, address: ev.address, port: ev.port, type: ev.type}
    EventBridge.dispatch(key, msg)

    {:noreply, state}
  end

  def handle_info(msg = {:stop, ev = %DetectorEv{}}, state) do
    Enum.each(state.listeners, fn listener ->
      send(listener, {:stop, ev})
    end)

    key = %{source: :sensor, address: ev.address, port: ev.port, type: ev.type}
    EventBridge.dispatch(key, msg)

    {:noreply, state}
  end

  def handle_info(msg = {:start, ev = %DetectorExitEv{}}, state) do
    Enum.each(state.listeners, fn listener ->
      send(listener, {:start, ev})
    end)

    key = %{source: :sensor, address: ev.address, port: ev.port}
    EventBridge.dispatch(key, msg)

    {:noreply, state}
  end

  def handle_info(msg = {:stop, ev = %DetectorExitEv{}}, state) do
    Enum.each(state.listeners, fn listener ->
      send(listener, {:stop, ev})
    end)

    key = %{source: :sensor, address: ev.address, port: ev.port}
    EventBridge.dispatch(key, msg)

    {:noreply, state}
  end

  def handle_info(msg = {:start, ev = %DetectorEntryEv{}}, state) do
    Enum.each(state.listeners, fn listener ->
      send(listener, {:start, ev})
    end)

    key = %{source: :sensor, address: ev.address, port: ev.port}
    EventBridge.dispatch(key, msg)

    {:noreply, state}
  end

  def handle_info(msg = {:stop, ev = %DetectorEntryEv{}}, state) do
    Enum.each(state.listeners, fn listener ->
      send(listener, {:stop, ev})
    end)

    key = %{source: :sensor, address: ev.address, port: ev.port}
    EventBridge.dispatch(key, msg)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    listeners =
      Enum.reject(state.listeners, fn listener ->
        pid == listener
      end)

    {:noreply, %{state | listeners: listeners}}
  end

  def handle_info({:more_debug, v}, state) when is_boolean(v) do
    Logger.info(fn -> "Setting detector more debug at #{inspect(v)}" end)
    newstate = %{state | debug: v}
    {:noreply, newstate}
  end

  defp process_event(%Event{address: a, port: p, value: v}, _state)
       when is_nil(a) or is_nil(p) or is_nil(v) do
    :error
  end

  defp process_event(ev = %Event{}, state) do
    port = state.config.port
    addr = state.config.address

    with ^port <- ev.port,
         ^addr <- ev.address do
      case state.config.balance do
        "NC" -> nc(ev, state)
        "NO" -> no(ev, state)
        "EOL" -> eol(ev, state)
        "DEOL" -> deol(ev, state)
        "TEOL" -> teol(ev, state)
        _ -> :error
      end
    else
      _ -> :not_me
    end
  end

  defp nc(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1

    case ev.value do
      v when v < th1 ->
        build_ev_type(:idle, ev.address, ev.port)

      _ ->
        build_ev_type(:alarm, ev.address, ev.port)
    end
  end

  defp no(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1

    case ev.value do
      v when v < th1 ->
        build_ev_type(:alarm, ev.address, ev.port)

      _ ->
        build_ev_type(:idle, ev.address, ev.port)
    end
  end

  defp eol(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    th2 = me.th2

    case ev.value do
      v when v < th1 ->
        build_ev_type(:short, ev.address, ev.port)

      v when v < th2 ->
        build_ev_type(:idle, ev.address, ev.port)

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
      v when v < th1 ->
        build_ev_type(:short, ev.address, ev.port)

      v when v < th2 ->
        build_ev_type(:idle, ev.address, ev.port)

      v when v < th3 ->
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
      v when v < th1 ->
        build_ev_type(:short, ev.address, ev.port)

      v when v < th2 ->
        build_ev_type(:idle, ev.address, ev.port)

      v when v < th3 ->
        build_ev_type(:alarm, ev.address, ev.port)

      v when v < th4 ->
        build_ev_type(:fault, ev.address, ev.port)

      _ ->
        build_ev_type(:tamper, ev.address, ev.port)
    end
  end

  defp build_ev_type(type, address, port) do
    %DetectorEv{
      type: type,
      address: address,
      port: port,
      id: nil
    }
  end

  defp debug_log(what, state) do
    case state.debug do
      true -> Logger.debug(what)
      _ -> nil
    end
  end
end
