defmodule DtCore.ScenarioLoader do
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
    Logger.info "Starting Scenario Loader"
    {:ok, nil}
  end

end
