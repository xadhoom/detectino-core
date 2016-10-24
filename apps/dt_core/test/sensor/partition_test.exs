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

  test "starts all sensors servers" do
    s1 = %SensorModel{name: "NC_1", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    s2 = %SensorModel{name: "NC_2", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 2}
    part = %PartitionModel{
      name: "prot", armed: @arm_disarmed,
      sensors: [s1, s2]
    }

    {:ok, ppid} = Partition.start_link({part, self})
    workers = Partition.count_sensors(part)

    assert 2 = workers

  end
end