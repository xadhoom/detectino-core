defmodule DtCore.StatusTracker do
  @moduledoc """
  Keeps track of all system alarms to have
  a current snapshot without having to query
  all sensors and partitions.
  """
  use GenServer

  require Logger

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting Status Tracker"
    {:ok, nil}
  end
end
