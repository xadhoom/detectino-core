defmodule DtCore.Test.StatusTrackerTest do
  use ExUnit.Case, async: false

  import Supervisor.Spec

  alias DtCore.Event, as: Event
  alias DtCore.StatusTracker
  alias DtCore.Sensor.Partition
  alias DtCore.Sensor.PartitionSup
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel

  setup_all do
    cache = :ets.new(:part_state_cache, [:set, :public])
    {:ok, [cache: cache]}
  end

  test "idle partition is not reported in alarm", ctx do
    {:ok, _, _} = start_idle_partition(ctx)

    assert StatusTracker.running_partitions() == 1
    assert StatusTracker.alarm_status() == false
  end

  test "report alarmed partition", ctx do
    {:ok, pid, part} = start_idle_partition(ctx)
    alarm_partition(pid, part)

    assert StatusTracker.running_partitions() == 1
    assert StatusTracker.alarm_status() == true
  end

  defp alarm_partition(pid, part) do
    :ok = Partition.arm(part, "ARM")

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    ev = %Event{address: "2", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
  end

  defp start_idle_partition(ctx) do
    sensors = [
      %SensorModel{name: "A", balance: "NC", th1: 10,
        partitions: [], enabled: true, address: "1", port: 1},
      %SensorModel{name: "B", balance: "NC", th1: 10,
        partitions: [], enabled: true, address: "2", port: 1}
      ]
    part = %PartitionModel{name: "prot", armed: "DISARM",
      sensors: sensors}

    {:ok, sup_pid} = PartitionSup.start_link()

    {ret, pid} = Supervisor.start_child(sup_pid,
      worker(Partition,[{part, ctx[:cache]}],
      restart: :transient, id: part.name))

    {ret, pid, part}
  end

end
