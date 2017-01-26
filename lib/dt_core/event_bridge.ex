defmodule DtCore.EventBridge do
  @moduledoc """
  Receives event from Sensors and Partition Workers and
  dispatches to Outputs using DtCore.OutputsRegistry.

  It also logs event sequences and provides a the event
  stream to subscribed listeners.

  Basically used as a more flexible bridge for Registry,
  because we need something more than a pure `===` match.
  """
  use GenServer

  alias DtCore.OutputsRegistry

  require Logger

  defstruct listeners: %{}

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def dispatch(key = %{}, payload) do
    GenServer.cast(__MODULE__, {:dispatch, key, payload})
  end

  def start_listening(filter_fun \\ fn(_) -> true end) do
    GenServer.call(__MODULE__, {:start_listening, self(), filter_fun})
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting Event Bridge"
    {:ok, %DtCore.EventBridge{}}
  end

  def handle_cast({:dispatch, key, payload}, state) do
    Registry.dispatch(OutputsRegistry.registry, key, fn listeners ->
      for {pid, _} <- listeners, do: send(pid, payload)
    end)
    dispatch_filtered(state, {key, payload})
    {:noreply, state}
  end

  def handle_call({:start_listening, pid, filter_fun}, _from, state) do
    #key = Base.encode64 :erlang.term_to_binary(pid)
    listeners = Map.put state.listeners, pid, %{filter: filter_fun}
    Process.monitor pid
    {:reply, {:ok, pid}, %DtCore.EventBridge{state | listeners: listeners}}
  end

  def handle_call({:stop_listening, pid}, _from, state) do
    #key = Base.encode64 :erlang.term_to_binary(pid)
    listeners = Map.delete state.listeners, pid
    Process.unlink pid
    {:reply, {:ok, pid}, %DtCore.EventBridge{state | listeners: listeners}}
  end

  def handle_info({:DOWN, _, _, pid, _}, state) do
    handle_call {:stop_listening, pid}, nil, state
    {:noreply, state}
  end

  defp dispatch_filtered(state, {key, payload}) do
    Enum.each state.listeners, fn({pid, v}) ->
      if v.filter.({key, payload}) do
        send pid, {:bridge, key, payload}
      end
    end
  end
end
