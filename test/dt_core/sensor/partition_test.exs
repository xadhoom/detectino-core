defmodule DtCore.Test.Sensor.Partition do
  use DtCore.EctoCase

  alias DtCore.Sensor.Worker
  alias DtCore.Sensor.Partition
  alias DtCore.Sensor.PartitionSup
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv
  alias DtCore.PartitionEv
  alias DtCore.Test.TimerHelper

  @arm_disarmed "DISARM"

  setup_all do
    {:ok, _} = DtCore.EventBridge.start_link()
    :ok
  end

  setup do
    {:ok, _} = Registry.start_link(:duplicate, DtCore.OutputsRegistry.registry)
    cache = :ets.new(:part_state_cache, [:set, :public])
    {:ok, [cache: cache]}
  end

  test "starts all sensors servers", ctx do
    s1 = %SensorModel{name: "NC_1", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    s2 = %SensorModel{name: "NC_2", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 2}
    part = %PartitionModel{
      name: "prot", armed: @arm_disarmed,
      sensors: [s1, s2]
    }

    {:ok, _ppid} = Partition.start_link({part, ctx[:cache]})
    workers = Partition.count_sensors(part)

    assert 2 = workers
  end

  test "no alarm but simple events if partion is not armed", ctx do
    sensor = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [sensor]}

    key = %{source: :sensor, address: "1", port: 1, type: :reading}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :partition, name: "prot", type: :reading}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    {:ok, pid} = Partition.start_link({part, ctx[:cache]})

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    {:start, %SensorEv{type: :reading, address: "1", port: 1}}
    |> assert_receive(5000)
    _msg
    |> refute_receive(1000)
  end

  test "triggers alarm on immediate sensor", ctx do
    sensor = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [sensor]}

    key = %{source: :sensor, address: "1", port: 1, type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :partition, name: "prot", type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    {:ok, pid} = Partition.start_link({part, ctx[:cache]})

    :ok = Partition.arm(part, "ARM")

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    {:start, %SensorEv{type: :alarm, address: "1", port: 1}}
    |> assert_receive(5000)

    {:start, %PartitionEv{type: :alarm, name: "prot"}}
    |> assert_receive(5000)
  end

  test "arm partial sensor", ctx do
    s_int = %SensorModel{name: "INT", balance: "NC", th1: 10,
        partitions: [], enabled: true, address: "1", port: 1, internal: true}
    s_ext = %SensorModel{name: "EXT", balance: "NC", th1: 10,
        partitions: [], enabled: true, address: "1", port: 2, internal: false}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [s_int, s_ext]}

    {:ok, _pid} = Partition.start_link({part, ctx[:cache]})

    :ok = Partition.arm(part, "ARMSTAY")

    assert Worker.armed?({s_int, part}) == false
    assert Worker.armed?({s_ext, part}) == true

    # TODO: find a way to check that arming respected the entry delay
  end

  test "arm partial sensor immediately", ctx do
    s_int = %SensorModel{name: "INT", balance: "NC", th1: 10,
        partitions: [], enabled: true, address: "1", port: 1, internal: true}
    s_ext = %SensorModel{name: "EXT", balance: "NC", th1: 10,
        partitions: [], enabled: true, address: "1", port: 2, internal: false}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [s_int, s_ext]}

    {:ok, _pid} = Partition.start_link({part, ctx[:cache]})

    :ok = Partition.arm(part, "ARMSTAYIMMEDIATE")

    assert Worker.armed?({s_int, part}) == false
    assert Worker.armed?({s_ext, part}) == true

    # TODO: find a way to check that arming zeroed the entry delay
  end

  test "ignore event if not for my sensors", ctx do
    sensor = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [sensor]}

    key = %{source: :sensor, address: "1", port: 1, type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :partition, name: "prot", type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    {:ok, pid} = Partition.start_link({part, ctx[:cache]})
    :ok = Partition.arm(part, "ARM")

    ev = %Event{address: "1", port: 2, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    _msg
    |> refute_receive(1000)
  end

  test "triggers partition alarms when partition is not armed and sensor is a 24h", ctx do
    sensor = %SensorModel{
      name: "sense1",
      full24h: true,
      address: "1", port: 1,
      balance: "DEOL", th1: 10, th2: 20, th3: 30,
      partitions: [],
      enabled: true
    }
    part = %PartitionModel{name: "part1", armed: @arm_disarmed, sensors: [sensor]}

    :ok = register_deol_listeners()

    {:ok, pid} = Partition.start_link({part, ctx[:cache]})
    # not really needed, but well
    :ok = Partition.disarm(part, "DISARM")

    ev = %Event{address: "1", port: 1, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    {:start, %SensorEv{type: :tamper, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {:start, %PartitionEv{type: :tamper, name: "part1"}}
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    {:stop, %PartitionEv{type: :tamper, name: "part1"}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {:start, %PartitionEv{type: :alarm, name: "part1"}}
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    {:start, %SensorEv{type: :standby, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {:start, %PartitionEv{type: :standby, name: "part1"}}
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    {:start, %SensorEv{type: :short, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    {:stop, %PartitionEv{type: :standby, name: "part1"}}
    |> assert_receive(5000)
    {:start, %PartitionEv{type: :short, name: "part1"}}
    |> assert_receive(5000)
  end

  test "does not trigger partition alarms when partition is not armed and sensor isn't 24h", ctx do
    sensor = %SensorModel{
      name: "sense1",
      full24h: false,
      address: "1", port: 1,
      balance: "DEOL", th1: 10, th2: 20, th3: 30,
      partitions: [],
      enabled: true
    }
    part = %PartitionModel{name: "part1", armed: @arm_disarmed, sensors: [sensor]}

    :ok = register_deol_listeners()

    {:ok, pid} = Partition.start_link({part, ctx[:cache]})
    # not really needed, but well
    :ok = Partition.disarm(part, "DISARM")

    ev = %Event{address: "1", port: 1, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    {:start, %SensorEv{type: :tamper, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {_op, %PartitionEv{}}
    |> refute_receive(1000)

    ev = %Event{address: "1", port: 1, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    {:start, %SensorEv{type: :reading, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {_op, %PartitionEv{}}
    |> refute_receive(1000)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    {:start, %SensorEv{type: :standby, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {_op, %PartitionEv{}}
    |> refute_receive(1000)

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    {:start, %SensorEv{type: :short, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {_op, %PartitionEv{}}
    |> refute_receive(1000)
  end

  test "dead process will resume correctly", ctx do
    sensor = %SensorModel{name: "NO", balance: "NO", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [sensor]}

    key = %{source: :sensor, address: "1", port: 1, type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    key = %{source: :partition, name: "prot", type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    {:ok, suppid} = PartitionSup.start_link

    {:ok, pid} = Supervisor.start_child(suppid,
      Supervisor.Spec.worker(Partition, [{part, ctx[:cache]}],
        restart: :transient, id: part.name))

    :ok = Partition.arm(part, "ARM")
    Process.exit(pid, :kill)
    refute Process.alive?(pid)

    TimerHelper.wait_until fn() ->
      assert Partition.alive?(part)
    end

    pid = Partition.get_pid(part)

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])

    {:start, %SensorEv{type: :alarm, address: "1", port: 1}}
    |> assert_receive(5000)

    {:start, %PartitionEv{type: :alarm, name: "prot"}}
    |> assert_receive(5000)
  end

  test "partion alarm is stopped when all sensors are idle", ctx do
    key = %{source: :sensor, address: "1", port: 1, type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :sensor, address: "2", port: 1, type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :partition, name: "prot", type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    {:ok, pid, part} = start_nc_idle_partition(ctx)

    :ok = Partition.arm(part, "ARM")

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    ev = %Event{address: "2", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    {:start, %SensorEv{type: :alarm, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "2", port: 1}}
    |> assert_receive(5000)

    {:start, %PartitionEv{type: :alarm, name: "prot"}}
    |> assert_receive(5000)

    ev = %Event{address: "2", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    {:stop, %SensorEv{type: :alarm, address: "2", port: 1}}
    |> assert_receive(5000)

    {_op,  %PartitionEv{}}
    |> refute_receive(1000)

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    {:stop, %PartitionEv{type: :alarm, name: "prot"}}
    |> assert_receive(5000)
  end

  test "partition alarm is stopped on disarm", ctx do
    key = %{source: :sensor, address: "1", port: 1, type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :sensor, address: "2", port: 1, type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :partition, name: "prot", type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    {:ok, pid, part} = start_nc_idle_partition(ctx)

    :ok = Partition.arm(part, "ARM")

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    ev = %Event{address: "2", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    {:start, %SensorEv{type: :alarm, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "2", port: 1}}
    |> assert_receive(5000)

    {:start, %PartitionEv{type: :alarm, name: "prot"}}
    |> assert_receive(5000)

    :ok = Partition.disarm(part, "DISARM")
    {:stop, %PartitionEv{type: :alarm, name: "prot"}}
    |> assert_receive(5000)
  end

  test "get partition alarm status", ctx do
    {:ok, _pid, part} = start_nc_idle_partition(ctx)
    assert :standby == Partition.alarm_status(part)
  end

  defp start_nc_idle_partition(ctx) do
    sensors = [
      %SensorModel{name: "A", balance: "NC", th1: 10,
        partitions: [], enabled: true, address: "1", port: 1},
      %SensorModel{name: "B", balance: "NC", th1: 10,
        partitions: [], enabled: true, address: "2", port: 1}
      ]
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: sensors}
    {ret, pid} = Partition.start_link({part, ctx[:cache]})
    {ret, pid, part}
  end

  defp register_deol_listeners do
    key = %{source: :sensor, address: "1", port: 1, type: :reading}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :sensor, address: "1", port: 1, type: :tamper}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :sensor, address: "1", port: 1, type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :sensor, address: "1", port: 1, type: :standby}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :sensor, address: "1", port: 1, type: :short}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    key = %{source: :partition, name: "part1", type: :tamper}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :partition, name: "part1", type: :alarm}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :partition, name: "part1", type: :standby}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])
    key = %{source: :partition, name: "part1", type: :short}
    Registry.register(DtCore.OutputsRegistry.registry, key, [])

    :ok
  end
end
