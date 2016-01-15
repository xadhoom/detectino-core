defmodule DtCore.Event do
  defstruct from: nil,
    type: nil,
    subtype: nil,
    port: nil,
    value: nil
end

defmodule DtCore.Receiver do
  use GenServer

  require Logger
  alias DtCore.Event
  alias DtWeb.Repo, as: Repo
  alias DtWeb.Sensor, as: Sensor

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def put(event = %Event{}) do
    GenServer.call __MODULE__, {:put, event}
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting Event Receiver"
    :timer.send_after(500, :start)
    {:ok, nil}
  end

  def handle_info(:start, _state) do
    sensors = DtWeb.Repo.all DtWeb.Sensor
    sensors = Enum.map(sensors, fn(sensor) -> sensor.address end)
    Logger.debug "Loaded #{length sensors} sensors"
    {:noreply, sensors}
  end

  def handle_call(rq, _, nil) do
    Logger.notice("System not yet ready for event #{inspect rq}")
    {:reply, nil, nil}
  end

  def handle_call({:put, event = %Event{}}, _from, state) do
    Logger.debug "Got event " <> inspect(event)
    state = case Enum.member?(state, event.from) do
      true ->
        Logger.debug("Found !")
        state
      false -> [ event.from | state ]
    end
    {:reply, nil, state}
  end

end
