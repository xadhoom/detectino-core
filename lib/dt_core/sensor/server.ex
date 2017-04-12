defmodule DtCore.Sensor.Server do
  @moduledoc """
  Server responsible of starting/stopping sensor workers,
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
  alias DtCore.Sensor.Partition
  alias DtCore.Sensor.PartitionSup
  alias DtWeb.Repo
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtWeb.ReloadRegistry

  require Logger

  #
  # Client APIs
  #
  def start_link(sup) do
    GenServer.start_link(__MODULE__, sup, [name: :sensor_server])
  end

  @doc """
  Reloads the server and workers.
  This stops workers, worker sup and reloads everything from DB
  """
  def reload do
    GenServer.call(:sensor_server, {:reload})
  end

  @doc """
  Returns the number of currently active workers
  """
  def partitions do
    GenServer.call(:sensor_server, {:partitions})
  end

  def sensors do
    GenServer.call(:sensor_server, {:sensors})
  end

  @doc """
  Check if the event is from a known sensor
  """
  def known_sensor?(ev = %BusEvent{}) do
    GenServer.call(:sensor_server, {:known_sensor, ev})
  end

  #
  # GenServer callbacks
  #
  def init(sup) do
    Logger.info "Supervisor #{inspect sup} started Sensor Server"
    {:ok, _myself} = Bus.start_listening
    send self(), :start
    {:ok, %{
        sup: sup,
        partition_sup: nil,
        sensors: [],
        partitions: [],
        receiver: self(),
        part_state_cache: nil
      }
    }
  end

  @doc false
  def handle_call({:partitions}, _from, state = %{partition_sup: nil}) do
    {:reply, {:error, :reloading}, state}
  end

  @doc false
  def handle_call({:partitions}, _from, state) do
    res = Supervisor.count_children(state.partition_sup)
    {:reply, {:ok, res.active}, state}
  end

  def handle_call({:sensors}, _from, state) do
    res = Enum.count(state.sensors)
    {:reply, {:ok, res}, state}
  end

  @doc false
  def handle_call({:reload}, _from, state) do
    {res, state} = do_reload(state)
    {:reply, res, state}
  end

  @doc false
  def handle_call({:known_sensor, ev = %BusEvent{}}, _from, state) do
    {ev, state} = {ev, state}
                  |> normalize_event
    known = Enum.member?(state.sensors, %{address: ev.address, port: ev.port})
    {:reply, known, state}
  end

  @doc """
  Starts the server by spawning the workers sup and all
  sensors from the DB
  """
  def handle_info(:start, state) do
    state = init_cache(state)
    case Supervisor.start_child(state.sup, supervisor(PartitionSup, [],
                                restart: :temporary)) do
      {:ok, partpid} ->
        Process.monitor partpid
        state = %{state | partition_sup: partpid}
        start_partitions(state)
        Registry.register(ReloadRegistry.registry, ReloadRegistry.key, [])
        {:noreply, state}
      {:error, err} ->
        Logger.error "Error starting Partition Sup #{inspect err}"
        {:stop, err, state}
    end
  end

  @doc false
  def handle_info({:reload}, state) do
    {:ok, state} = do_reload(state)
    {:noreply, state}
  end

  @doc """
  Handle :normal :DOWN messages from our worker sup
  """
  def handle_info({:DOWN, _ref, _process, _pid, :normal}, state) do
    Logger.info "Partition supervisor down, normal"
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, _process, _pid, :shutdown}, state) do
    Logger.info "Partition supervisor down, shutdown"
    {:noreply, state}
  end

  @doc """
  Handle not :normal :DOWN messages from our worker sup
  and restart everything
  """
  def handle_info({:DOWN, _ref, _process, pid, reason}, state) do
    partition_sup = state.partition_sup
    case pid do
      ^partition_sup ->
        Logger.error "Partition Sup died with reason #{inspect reason}, I quit!"
        {:stop, reason, state}
      any ->
        Logger.info "Got :DOWN message from #{inspect any} " <>
          "but is not my partition worker supervisor, ignoring...."
        {:noreply, state}
    end
  end

  @doc """
  Receives an event from the Bus and dispatch to the correct
  worker, by looking the address, port tuple.
  Also, if the sensor sending event is not on local state,
  load it from Repo and add it if is not present.
  Basically a sort of autodiscovery
  """
  def handle_info({:event, ev = %BusEvent{}}, state) do
    Logger.debug "Received event #{inspect ev} from bus"
    {:ok, state} = dispatch_event({ev, state})
    {:noreply, state}
  end

  defp init_cache(state) do
    case state.part_state_cache do
      nil -> nil
      _ -> :ets.delete(state.part_state_cache)
    end
    %{state | part_state_cache: :ets.new(:part_state_cache, [:set, :public])}
  end

  defp do_reload(state) do
    :ok = Supervisor.stop(state.partition_sup, :normal)
    send self(), :start
    {:ok, %{state | partition_sup: nil}}
  end

  defp dispatch_event({ev = %BusEvent{}, state}) do
    {ev, state} = {ev, state}
                  |> normalize_event
                  |> cache_sensor

    # send the event to all partitions since we do not know
    # where the sensor is (can be attached to many partitions)
    state.partition_sup
    |> Supervisor.which_children
    |> Enum.each(fn(child) ->
      {_id, pid, _type, _modules} = child
      Logger.debug "sending event #{inspect ev} to partition #{inspect pid}"
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

  defp start_partitions(state) do
    PartitionModel
    |> Repo.all
    |> Repo.preload(:sensors)
    |> Enum.each(fn(partition) ->
      start_partition(partition, state)
    end)
  end

  defp start_partition(partition, state) do
    id = partition.name
    case Supervisor.start_child(state.partition_sup,
          worker(Partition,[{partition, state.part_state_cache}],
            restart: :transient, id: id)) do
      {:ok, pid} ->
        Logger.info "Started partition worker with pid #{inspect pid}"
      {:error, err} ->
        Logger.error "Cannot start partition worker: " <>
          "#{inspect err} #{inspect partition}"
    end
  end

end
