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

  #
  # Client APIs
  #
  def start_link(config = %SensorModel{}) do
    Logger.debug("Starting sensor with #{inspect config} config")
    GenServer.start_link(__MODULE__, config)
  end

  #
  # GenServer callbacks
  #
  def init(config) do
    Logger.info "Starting Sensor Worker with addr #{inspect config.address} " <>
      "and port #{inspect config.port}"
    #{:ok, _myself} = Handler.start_listening
    #{:ok, pid} = Action.start_link
    {:ok, %{}}
  end

  def handle_info({:event, _ev = %Event{}}, state) do
    Logger.debug("Got event from server")
    {:noreply, state}
  end

end
