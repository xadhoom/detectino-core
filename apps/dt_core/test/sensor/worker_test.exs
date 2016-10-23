defmodule DtCore.Test.Sensor.Worker do
  use DtCore.EctoCase

  alias DtCore.Sensor.Worker
  alias DtCore.Sensor.Partition
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv

  @arm_disarmed "DISARM"
  @arm_armed "ARM"

  @nc_model %SensorModel{name: "NC", address: "1", port: 1,
    balance: "NC", th1: 10, partitions: [], enabled: true}
  @no_model %SensorModel{name: "NO", address: "1", port: 1,
    balance: "NO", th1: 10, partitions: [], enabled: true}
  @eol_model %SensorModel{name: "EOL", address: "1", port: 1,
    balance: "EOL", th1: 10, th2: 20, partitions: [], enabled: true}
  @deol_model %SensorModel{name: "DEOL", address: "1", port: 1,
    balance: "DEOL", th1: 10, th2: 20, th3: 30, partitions: [],
    enabled: true}
  @teol_model %SensorModel{name: "TEOL", address: "1", port: 1,
    balance: "TEOL", th1: 10, th2: 20, th3: 30, th4: 40, partitions: [],
    enabled: true}

  test "no alarm but simple events if partion is not armed" do
    part = %PartitionModel{name: "prot", armed: @arm_disarmed}
    config = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [part], enabled: true, address: "1", port: 1}
    {:ok, _ppid} = Partition.start_link({part, self})
    {:ok, pid} = Worker.start_link({config, self})

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    [%SensorEv{type: :reading, address: "1", port: 1}]
    |> assert_receive(5000)
  end

  test "triggers alarm on immediate sensor" do
    part = %PartitionModel{name: "part1", armed: @arm_armed}
    config = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [part], enabled: true, address: "1", port: 1}
    {:ok, _ppid} = Partition.start_link({part, self})
    {:ok, pid} = Worker.start_link({config, self})

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    [%SensorEv{type: :alarm, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)
  end

  test "triggers alarms when partition is not armed and sensor is a 24h" do
    part = %PartitionModel{name: "part1", armed: @arm_disarmed}
    config = %SensorModel{
      name: "sense1",
      full24h: true,
      address: "1", port: 1,
      balance: "TEOL", th1: 10, th2: 20, th3: 30, th4: 40,
      partitions: [part],
      enabled: true
    }
    {:ok, _ppid} = Partition.start_link({part, self})
    {:ok, pid} = Worker.start_link({config, self})

    ev = %Event{address: "1", port: 1, value: 45}
    :ok = Process.send(pid, {:event, ev}, [])
    [%SensorEv{type: :tamper, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    [%SensorEv{type: :fault, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    [%SensorEv{type: :alarm, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    [%SensorEv{type: :standby, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    [%SensorEv{type: :short, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)
  end

  test "alarm on entry is delayed by partion time if sensor is a delayed one" do
    part = %PartitionModel{
      name: "part1",
      armed: @arm_armed,
      entry_delay: 1
      }
    config = %SensorModel{
      name: "sense2",
      address: "1",
      port: 1,
      balance: "NC",
      th1: 10,
      entry_delay: true,
      partitions: [part],
      enabled: true
    }
    {:ok, _ppid} = Partition.start_link({part, self})
    {:ok, pid} = Worker.start_link({config, self})
    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    [%SensorEv{type: :alarm, address: "1", port: 1, delayed: true}]
    |> assert_receive(5000)

    [%SensorEv{type: :alarm, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)
  end
  
  test "delayed alarm uses min delay values of partitions" do
    part1 = %PartitionModel{name: "part1", armed: @arm_armed, entry_delay: 1}
    part2 = %PartitionModel{name: "part2", armed: @arm_armed, entry_delay: 10}
    config = %SensorModel{
      name: "sense2",
      address: "1",
      port: 1,
      balance: "NC",
      th1: 10,
      entry_delay: true,
      partitions: [part1, part2],
      enabled: true
    }
    {:ok, _ppid1} = Partition.start_link({part1, self})
    {:ok, _ppid2} = Partition.start_link({part2, self})
    {:ok, pid} = Worker.start_link({config, self})
    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    # we get an immediate delayed event, one per partition
    [%SensorEv{type: :alarm, address: "1", port: 1, delayed: true},
     %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}]
    |> assert_receive(2000)

    [%SensorEv{type: :alarm, address: "1", port: 1, delayed: false},
     %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)
  end

  test "delayed alarm on entry is cancelled if partition is unarmed in time" do
    part = %PartitionModel{
      name: "part1",
      armed: @arm_armed,
      entry_delay: 1
      }
    config = %SensorModel{
      name: "sense1",
      balance: "NC",
      th1: 10,
      entry_delay: true,
      partitions: [part],
      address: "1", port: 1,
      enabled: true
    }
    {:ok, ppid} = Partition.start_link({part, self})
    {:ok, pid} = Worker.start_link({config, self})
    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    [%SensorEv{type: :alarm, address: "1", port: 1, delayed: true}]
    |> assert_receive(5000)

    GenServer.stop(ppid)
    part = %PartitionModel{part | armed: @arm_disarmed}
    {:ok, _ppid} = Partition.start_link({part, self})

    [%SensorEv{type: :reading, address: "1", port: 1, delayed: false}]
    |> assert_receive(5000)
  end 

  test "standby values should fail if no data" do
    config = %SensorModel{}
    assert_raise MatchError, fn -> Worker.start_link({config, self}) end
  end

  test "correctly handle dead partition worker" do
    part = %PartitionModel{
      name: "part1",
      armed: @arm_armed,
      entry_delay: 1
      }
    config = %SensorModel{
      name: "sense1",
      balance: "NC",
      th1: 10,
      entry_delay: true,
      partitions: [part],
      address: "1", port: 1,
      enabled: true
    }
    Process.flag(:trap_exit, true)
    {:ok, pid} = Worker.start_link({config, self})
    {:EXIT, ^pid, :dead_partitions}
    |> assert_receive(1000)
  end
end