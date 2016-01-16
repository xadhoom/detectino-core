defmodule DtCore.Receiver do
  use GenServer

  import Ecto.Query, only: [from: 2]

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

  def put(event = %Event{address: a, port: p}) when (is_binary(a) or is_number(a)) and is_number(p) do
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
  
  @doc """
  Initialize the state by loading all configured sensors in memory.
  """
  def handle_info(:start, _state) do
    q = from s in Sensor,
      where: s.configured == true
    sensors = Repo.all(q)

    sensors = Enum.map(sensors, fn(sensor) -> sensor.address end)
    Logger.debug "Loaded #{length sensors} sensors"
    {:noreply, sensors}
  end

  def handle_call(rq, _, nil) do
    Logger.info("System not yet ready for event #{inspect rq}")
    {:reply, nil, nil}
  end

  @doc """
  When we receive events, if the sensor is not in my list,
  check it on the Repo and load in memory if configured already,
  otherwise if is not configured, just ignore it if already on Repo,
  or add to the Repo if needs to.
  """
  def handle_call({:put, event = %Event{}}, _from, state) do
    Logger.debug "Got event " <> inspect(event)
    state = case Enum.member?(state, event.address) do
      true ->
        Logger.debug("Sensor #{event.address} already in my list")
        state
      false -> maybe_on_repo(event, state)
    end
    {:reply, nil, state}
  end

  defp maybe_on_repo(event = %Event{}, state) do
    address = to_string(event.address)
    q = from s in Sensor,
      where: s.address == ^address
    sensor = Repo.one(q)
    state = 
      case sensor do
        %Sensor{configured: true} -> [ event.address | state ]
        %Sensor{configured: false} -> state
        nil ->
          add_on_repo(event)
          state
      end
    state
  end

  defp add_on_repo(event = %Event{}) do
    address = to_string(event.address)
    Sensor.changeset(%Sensor{}, %{address: address, port: event.port, configured: false}) |> Repo.insert!
    Logger.debug("inserted new sensor with address #{address}")
  end

end
