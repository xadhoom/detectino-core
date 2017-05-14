defmodule DtCore.Monitor.Detector do
  @moduledoc """
  Worker for sensor.
  Handles all the logic when it's values changes
  (which is reported with an event from the DtBus app)
  """
  use GenServer

  require Logger

  alias DtWeb.Sensor, as: SensorModel

  alias DtCore.Event
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.DetectorEntryEv
  alias DtCore.Monitor.Utils
  alias DtCore.Monitor.DetectorFsm

  # Internal types

  @typep t :: %__MODULE__{config: %SensorModel{},
    fsm: pid, listeners: list(pid),
    exit_timeout: non_neg_integer,
    entry_timeout: non_neg_integer
  }
  defstruct config: nil,
    fsm: nil,
    listeners: [],
    exit_timeout: 100_000,
    entry_timeout: 100_000

  #
  # Client APIs
  #
  def start_link({config = %SensorModel{}}) do
    {:ok, name} = Utils.sensor_server_name(config)
    GenServer.start_link(__MODULE__, {config}, name: name)
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

  def subscribe(server, timeouts = {entry_timeout, exit_timeout}) do
    GenServer.call(server, {:subscribe, self(), timeouts})
  end

  #
  # GenServer Callbacks
  #
  @spec init({%SensorModel{}}) :: {:ok, Detector.t}
  def init({config}) do
    {:ok, fsm} = DetectorFsm.start_link({config, self()})
    {:ok, %__MODULE__{fsm: fsm, config: config}}
  end

  def handle_call(:status, _from, state) do
    status = DetectorFsm.status(state.fsm)
    {:reply, status, state}
  end

  def handle_call({:subscribe, pid, {entry_timeout, exit_timeout}},
      _from, state) when is_pid(pid) do
    listeners = [pid | state.listeners]
    Process.monitor pid

    entry_timeout = if entry_timeout < state.entry_timeout do
      entry_timeout
    else
      state.entry_timeout
    end
    exit_timeout = if exit_timeout < state.exit_timeout do
      exit_timeout
    else
      state.exit_timeout
    end

    {:reply, :ok,
      %__MODULE__{state | listeners: listeners,
        exit_timeout: exit_timeout, entry_timeout: entry_timeout}
    }
  end

  def handle_call(:arm, _from, state) do
    case state.config.exit_delay do
      true ->
        :ok = DetectorFsm.arm(state.fsm, state.exit_timeout)
      false ->
        :ok = DetectorFsm.arm(state.fsm, 0)
    end
    {:reply, :ok, state}
  end

  @spec handle_info({:event, %Event{}}, Detector.t) :: {:noreply, Detector.t}
  def handle_info({:event, ev = %Event{}}, state) do
    case process_event(ev, state) do
      :error ->
        Logger.warn "Cannot decode event %{inspect ev}"
      v ->
        DetectorFsm.event(state.fsm, v)
    end
    {:noreply, state}
  end

  def handle_info({:start, ev = %DetectorEv{}}, state) do
    Enum.each(state.listeners, fn(listener) ->
      send listener, {:start, ev}
    end)
    {:noreply, state}
  end

  def handle_info({:stop, ev = %DetectorEv{}}, state) do
    Enum.each(state.listeners, fn(listener) ->
      send listener, {:stop, ev}
    end)
    {:noreply, state}
  end

  def handle_info({:start, ev = %DetectorExitEv{}}, state) do
    Enum.each(state.listeners, fn(listener) ->
      send listener, {:start, ev}
    end)
    {:noreply, state}
  end

  def handle_info({:stop, ev = %DetectorExitEv{}}, state) do
    Enum.each(state.listeners, fn(listener) ->
      send listener, {:stop, ev}
    end)
    {:noreply, state}
  end

  defp process_event(%Event{address: a, port: p, value: v}, _state)
    when is_nil(a) or is_nil(p) or is_nil(v) do
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
    %DetectorEv{
      type: type,
      address: address,
      port: port
    }
  end

end
