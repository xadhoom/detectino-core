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
    {:noreply, state}
  end
end
