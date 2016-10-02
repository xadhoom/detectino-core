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

end
