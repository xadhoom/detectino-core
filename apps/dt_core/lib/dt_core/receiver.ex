defmodule DtCore.Receiver do
  @moduledoc """
  Receive an event and pass it to next step, while keeping
  in memory a list of active and configured %{sensor, port}.

  We don't care about the value here, just create a new entry into
  the database if the sender is not known and not already configured.
  """
  use GenServer

  import Ecto.Query, only: [from: 2]

  require Logger
  alias DtCore.Event
  alias DtWeb.Repo, as: Repo
  alias DtWeb.Sensor, as: Sensor

  #
  # Client APIs
  #
  def start_link(autostart \\ true) do
    GenServer.start_link(__MODULE__, autostart, name: __MODULE__)
  end

  def put(ev = %Event{address: a, port: p,
    type: t, subtype: s, value: v}) when a != nil and is_number(p)
    and is_atom(t) and is_atom(s) and t != nil and s != nil do

    ev = %Event{address: to_string(ev.address), port: ev.port}
    GenServer.call __MODULE__, {:put, ev}
  end

  #
  # GenServer callbacks
  #
  def init(autostart) do
    Logger.info "Starting Event Receiver"
    case autostart do
      true -> :timer.send_after(500, :start)
        {:ok, nil}
      _ -> {:ok, []}
    end
  end
  
  @doc """
  Initialize the state by loading all configured sensors in memory.
  """
  def handle_info(:start, _state) do
    q = from s in Sensor,
      where: s.configured == true
    sensors = Repo.all(q)

    sensors = Enum.map(sensors, fn(sensor) -> %{address: sensor.address, port: sensor.port} end)
    Logger.debug "Loaded #{length sensors} sensors"
    {:noreply, sensors}
  end

  def handle_call(rq, _from, nil) do
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
    state = case Enum.member?(state, %{address: event.address, port: event.port}) do
      true ->
        Logger.debug("Sensor #{event.address}:#{event.port} already in my list")
        state
      false -> maybe_on_repo(event, state)
    end
    {:reply, nil, state}
  end

  defp maybe_on_repo(event = %Event{address: a}, state) when is_binary(a) do
    q = from s in Sensor,
      where: s.address == ^event.address and s.port == ^event.port
    sensor = Repo.one(q)
    state = 
      case sensor do
        %Sensor{configured: true} -> [ %{address: event.address, port: event.port} | state ]
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
