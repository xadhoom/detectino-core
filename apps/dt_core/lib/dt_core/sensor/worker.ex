defmodule DtCore.Sensor.Worker do
  @moduledoc """
  Worker for sensor.
  Handles all the logic when it's values changes
  (which is reported with an event from the DtBus app)
  """
  use GenServer

  require Logger
  alias DtWeb.Sensor, as: SensorModel
  alias DtCore.Event, as: Event
  alias DtWeb.Repo

  #
  # Client APIs
  #
  def start_link(config = %SensorModel{}) do
    Logger.debug("Starting sensor worker with #{inspect config} config")
    GenServer.start_link(__MODULE__, config)
  end

  #
  # GenServer callbacks
  #
  def init(config) do
    Logger.info "Starting Sensor Worker with addr #{config.address} " <>
      "and port #{config.port}"
    {:ok, %{config: config}}
  end

  def handle_info({:event, ev = %Event{}}, state) do
    case state.config.enabled do
      false -> Logger.debug("Got event from server, but I'm not online, ignoring")
      true -> Logger.debug("Got event from server") 
      _ -> Logger.debug("Uh? Cannot get enabled status: #{inspect ev}")
    end
    {:noreply, state}
  end

  @doc """
  handles the sensor event and spits out the system event used
  to trigger actions.
  The function is not private because I want to test it :)
  """
  def process_event(%Event{address: a, port: p, value: v}, state) when is_nil(a) or is_nil(p) or is_nil(v) do
    {:error, state}
  end

  def process_event(ev = %Event{}, state) do
    case state.config.balance do
      "NC" -> nc(ev, state)
      "NO" -> no(ev, state)
      "EOL" -> eol(ev, state)
      "DEOL" -> deol(ev, state)
      "TEOL" -> teol(ev, state)
      _ -> {:error, state}
    end
  end

  defp nc(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    case ev.value do
      v when (v < th1) ->
        ret = build_ev_type(:standby, ev.address, ev.port)
        {ret, state}
      _ -> 
        ret = build_ev_type(:alarm, ev.address, ev.port)
        {ret, state}
    end
  end

  defp no(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    case ev.value do
      v when (v < th1) ->
        ret = build_ev_type(:alarm, ev.address, ev.port)
        {ret, state}
      _ -> 
        ret = build_ev_type(:standby, ev.address, ev.port)
        {ret, state}
    end
  end

  defp eol(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    th2 = me.th2
    case ev.value do
      v when (v < th1) ->
        ret = build_ev_type(:short, ev.address, ev.port)
        {ret, state}
      v when (v < th2) ->
        ret = build_ev_type(:standby, ev.address, ev.port)
        {ret, state}
      _ -> 
        ret = build_ev_type(:alarm, ev.address, ev.port)
        {ret, state}
    end
  end

  defp deol(ev = %Event{}, state) do
    me = state.config
    th1 = me.th1
    th2 = me.th2
    th3 = me.th3
    case ev.value do
      v when (v < th1) ->
        ret = build_ev_type(:short, ev.address, ev.port)
        {ret, state}
      v when (v < th2) ->
        ret = build_ev_type(:standby, ev.address, ev.port)
        {ret, state}
      v when (v < th3) ->
        ret = build_ev_type(:alarm, ev.address, ev.port)
        {ret, state}
      _ -> 
        ret = build_ev_type(:tamper, ev.address, ev.port)
        {ret, state}
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
        ret = build_ev_type(:short, ev.address, ev.port)
        {ret, state}
      v when (v < th2) ->
        ret = build_ev_type(:standby, ev.address, ev.port)
        {ret, state}
      v when (v < th3) ->
        ret = build_ev_type(:alarm, ev.address, ev.port)
        {ret, state}
      v when (v < th4) ->
        ret = build_ev_type(:fault, ev.address, ev.port)
        {ret, state}
      _ -> 
        ret = build_ev_type(:tamper, ev.address, ev.port)
        {ret, state}
    end
  end

  defp build_ev_type(type, address, port) do
    type = Atom.to_string(type)
    port = Integer.to_string(port)
    type <> "_" <> address <> "_" <> port
    |> String.to_atom
  end

end
