defmodule DtCore.Test.Sensor.Partition do
  use DtCore.EctoCase

  alias DtCore.Sensor.Partition
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv
  alias DtCore.PartitionEv

  @arm_disarmed "DISARM"
  @arm_armed "ARM"

  test "starts all sensors servers" do
    s1 = %SensorModel{name: "NC_1", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    s2 = %SensorModel{name: "NC_2", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 2}
    part = %PartitionModel{
      name: "prot", armed: @arm_disarmed,
      sensors: [s1, s2]
    }

    {:ok, _ppid} = Partition.start_link({part, self})
    workers = Partition.count_sensors(part)

    assert 2 = workers
  end

  test "no alarm but simple events if partion is not armed" do
    sensor = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [sensor]}

    {:ok, pid} = Partition.start_link({part, self})

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    %SensorEv{type: :reading, address: "1", port: 1}
    |> assert_receive(5000)
  end

  test "triggers alarm on immediate sensor" do
    sensor = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [sensor]}

    {:ok, pid} = Partition.start_link({part, self})

    :ok = Partition.arm(part, "ARM")

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    %SensorEv{type: :alarm, address: "1", port: 1}
    |> assert_receive(5000)

    %PartitionEv{type: :alarm, name: "prot"}
    |> assert_receive(5000)
  end

  test "ignore event if not for my sensors" do
    sensor = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    part = %PartitionModel{name: "prot", armed: @arm_disarmed,
      sensors: [sensor]}

    {:ok, pid} = Partition.start_link({part, self})
    :ok = Partition.arm(part, "ARM")

    ev = %Event{address: "1", port: 2, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    %SensorEv{}
    |> refute_receive(1000)
  end

end