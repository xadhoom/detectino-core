defmodule DtCore.Monitor.Controller do
  @moduledoc """
  Controller responsible of starting/stopping sensor detectors,
  via the Sensor Supervisor.
  Also receives messages from the Bus, normalize them and
  routes to the relevant worker, by looking into the address, port tuple.

  Performs also autodiscovery, by creating new sensors records
  into the Repo and starting the worker, if needed.
  """
  use GenServer

  import Supervisor.Spec
  import Ecto.Query, only: [from: 2]

  alias DtBus.Can, as: Bus
  alias DtBus.Event, as: BusEvent

  alias DtCore.Event
  alias DtCore.Monitor.Utils
  alias DtCore.Monitor.Partition
  alias DtCore.Monitor.Detector

  alias DtWeb.Repo
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtWeb.ReloadRegistry

  require Logger

  #
  # Client APIs
  #
  def start_link(sup) do
    GenServer.start_link(__MODULE__, sup, [name: :sensors_controller])
  end

  @doc """
  Reloads the server and workers.
  If no config is given, reloads everything from DB, otherwise from the passed
  tuple {}
  """
  @spec reload() :: :ok
  def reload do
    GenServer.cast(:sensors_controller, {:reload})
    :ok
  end

  @spec reload({list(%SensorModel{}), list(%PartitionModel{})}) :: :ok
  def reload({sensors, partitions}) do
    GenServer.call(:sensors_controller, {:start, {sensors, partitions}})
  end

  @doc """
  Stops all the workers without restarting the controller
  """
  def stop_workers do
    GenServer.call(:sensors_controller, {:stop_workers})
    :ok
  end

  @doc """
  Returns the number of currently active partitions
  """
  def partitions do
    GenServer.call(:sensors_controller, {:partitions})
  end

  @doc """
  Return the pids of the running partitions
  """
  def get_partitions do
    GenServer.call(:sensors_controller, {:get_partitions})
  end

  @doc """
  Return the pids of the running detectors
  """
  def get_sensors do
    GenServer.call(:sensors_controller, {:get_sensors})
  end

  @doc """
  Returns the number of currently active sensors (detectors)
  """
  def sensors do
    GenServer.call(:sensors_controller, {:sensors})
  end

  @doc """
  Check if the event is from a known sensor
  """
  def known_sensor?(ev = %BusEvent{}) do
    GenServer.call(:sensors_controller, {:known_sensor, ev})
  end

  #
  # GenServer callbacks
  #
  def init(sup) do
    Logger.info fn -> "Supervisor #{inspect sup} started Sensor Controller" end
    {:ok, _myself} = Bus.start_listening
    send self(), :start
    {:ok, %{
        sup: sup,
        sensors: [],
        detector_workers: [],
        partition_workers: [],
        started: false
      }
    }
  end

  @doc false
  def handle_call({:partitions}, _from, state = %{partitions_sup: nil}) do
    {:reply, {:error, :reloading}, state}
  end

  @doc false
  def handle_call({:partitions}, _from, state) do
    res = Enum.count(state.partition_workers)
    {:reply, {:ok, res}, state}
  end

  def handle_call({:get_partitions}, _from, state) do
    pids = Enum.map(state.partition_workers, fn({_, pid}) ->
      pid
    end)
    {:reply, pids, state}
  end

  @doc false
  def handle_call({:sensors}, _from, state = %{detectors_sup: nil}) do
    {:reply, {:error, :reloading}, state}
  end

  @doc false
  def handle_call({:sensors}, _from, state) do
    res = Enum.count(state.sensors)
    {:reply, {:ok, res}, state}
  end

  def handle_call({:get_sensors}, _from, state) do
    pids = Enum.map(state.detector_workers, fn({_, pid}) ->
      pid
    end)
    {:reply, pids, state}
  end

  @doc false
  def handle_call({:known_sensor, ev = %BusEvent{}}, _from, state) do
    {ev, state} = {ev, state}
                  |> normalize_event
    known = Enum.member?(state.sensors, %{address: ev.address, port: ev.port})
    {:reply, known, state}
  end

  def handle_call({:stop_workers}, _from, state) do
    Logger.info "Stopping all controller workers"

    Enum.each(state.partition_workers, fn(worker) ->
      stop_partition(worker, state)
    end)
    Enum.each(state.detector_workers, fn(worker) ->
      stop_detector(worker, state)
    end)

    {:reply, :ok, %{state | started: false,
      partition_workers: [], detector_workers: []}}
  end

  def handle_call({:start, {sensors, partitions}}, _from, state) do
    Logger.info("Reloading processes with injected config!")

    Enum.each(state.partition_workers, fn(worker) ->
      IO.inspect worker
      stop_partition(worker, state)
    end)
    Enum.each(state.detector_workers, fn(worker) ->
      IO.inspect worker

      stop_detector(worker, state)
    end)

    detector_workers = Enum.map(sensors, fn(sensor) ->
      {:ok, id, pid} = start_detector(sensor, state)
      {id, pid}
    end)

    partition_workers = Enum.map(partitions, fn(partition) ->
      {:ok, id, pid} = start_partition(partition, state)
      {id, pid}
    end)

    Registry.register(ReloadRegistry.registry, ReloadRegistry.key, [])
    {:reply, :ok, %{state | detector_workers: detector_workers,
      partition_workers: partition_workers, started: true}}
  end

  def handle_cast({:reload}, state = %{started: false}) do
    {:noreply, state}
  end
  def handle_cast({:reload}, state) do
    Logger.info("Reloading processes!")
    Enum.each(state.partition_workers, fn(worker) ->
      stop_partition(worker, state)
    end)
    Enum.each(state.detector_workers, fn(worker) ->
      stop_detector(worker, state)
    end)
    send self(), :start

    {:noreply, %{state | started: false,
      partition_workers: [], detector_workers: []}}
  end

  def handle_info({:reload}, state) do
    handle_cast({:reload}, state)
  end

  @doc """
  Start all workers by spawning a process for each
  detector and partition. The order is important, since
  partitions subscribe to sensors, they must be started
  after detectors.
  """
  def handle_info(:start, state =  %{started: false}) do
    detector_workers = SensorModel
    |> Repo.all
    |> Enum.map(fn(sensor) ->
      {:ok, id, pid} = start_detector(sensor, state)
      {id, pid}
    end)

    partition_workers = PartitionModel
    |> Repo.all
    |> Repo.preload(:sensors)
    |> Enum.map(fn(partition) ->
      {:ok, id, pid} = start_partition(partition, state)
      {id, pid}
    end)

    Registry.register(ReloadRegistry.registry, ReloadRegistry.key, [])
    {:noreply, %{state | detector_workers: detector_workers,
      partition_workers: partition_workers, started: true}}
  end

  @doc """
  Receives an event from the Bus and dispatch to the correct
  worker, by looking the address, port tuple.
  Also, if the sensor sending event is not on local state,
  load it from Repo and add it if is not present.
  Basically a sort of autodiscovery
  """
  def handle_info({:event, ev = %BusEvent{}}, state) do
    Logger.debug fn -> "Received event #{inspect ev} from bus" end
    {:ok, state} = dispatch_event({ev, state})
    {:noreply, state}
  end

  defp dispatch_event({ev = %BusEvent{}, state}) do
    {ev, state} = {ev, state}
                  |> normalize_event
                  |> cache_sensor

    # send the event to all detectors
    Enum.each(state.detector_workers, fn(pid) ->
      Logger.debug fn ->
        "sending event #{inspect ev} to detector #{inspect pid}"
      end
      send pid, {:event, ev}
    end)

    {:ok, state}
  end

  # translate from a Bus Event to a Core event
  defp normalize_event({ev = %BusEvent{}, state}) do
    ev = struct(Event, Map.from_struct (
      %BusEvent{ev | address: to_string(ev.address)}))
    {ev, state}
  end

  # check if the sensor is in our state, if not try to grab it from the repo
  defp cache_sensor({ev = %Event{}, state}) do
    case Enum.member?(state.sensors, %{address: ev.address, port: ev.port}) do
      true -> {ev, state}
      false -> maybe_on_repo({ev, state})
    end
  end

  # check if the event is from one sensor on the repo, if yes add to local cache
  defp maybe_on_repo({ev = %Event{}, state}) do
    q = from s in SensorModel,
             where: s.address == ^ev.address and s.port == ^ev.port

    case Repo.one(q) do
      nil -> add_on_repo({ev, state})
      _record ->
        ss = [%{address: ev.address, port: ev.port} | state.sensors]
        {ev, %{state | sensors: ss}}
    end
  end

  # sensor was not in our repo, so add it and cache on state.
  defp add_on_repo({ev = %Event{}, state}) do
    %SensorModel{}
    |> SensorModel.create_changeset(%{
      address: ev.address, port: ev.port, name: "AUTO"
    })
    |> Repo.insert!
    ss = [%{address: ev.address, port: ev.port} | state.sensors]
    {ev, %{state | sensors: ss}}
  end

  defp start_detector(sensor, state) do
    {:ok, id} = Utils.sensor_server_name(sensor)
    {:ok, pid} = Supervisor.start_child(state.sup,
      worker(Detector, [{sensor}],
      restart: :transient, id: id))
    {:ok, id, pid}
  end

  defp stop_detector({id, _pid}, state) do
    :ok = Supervisor.terminate_child(state.sup, id)
    Supervisor.delete_child(state.sup, id)
  end

  defp start_partition(partition, state) do
    {:ok, id} = Utils.partition_server_name(partition)
    {:ok, pid} = Supervisor.start_child(state.sup,
      worker(Partition, [partition],
      restart: :transient, id: id))
    {:ok, id, pid}
  end

  defp stop_partition({id, _pid}, state) do
    :ok = Supervisor.terminate_child(state.sup, id)
    Supervisor.delete_child(state.sup, id)
  end

end
