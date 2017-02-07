defmodule DtCore.Test.StatusTrackerTest do
  use ExUnit.Case, async: false

  import Supervisor.Spec

  alias DtCore.Event, as: Event
  alias DtCore.StatusTracker
  alias DtCore.Sensor.Partition
  alias DtCore.Sensor.PartitionSup
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Test.TimerHelper

  setup_all do
    cache = :ets.new(:part_state_cache, [:set, :public])
    {:ok, [cache: cache]}
  end

  setup do
    cache = :ets.new(:part_state_cache, [:set, :public])

    on_exit fn ->
      # give sometime to process to exit
      TimerHelper.wait_until fn ->
        assert Process.whereis(PartitionSup) == nil
      end
    end

    {:ok, [cache: cache]}
  end

  test "idle partition is not reported in alarm", ctx do
    {:ok, _, _} = start_idle_partition(ctx)

    assert StatusTracker.running_partitions() == 1
    assert StatusTracker.alarmed?() == false
  end

  test "report not armed partition", ctx do
    {:ok, _, _} = start_idle_partition(ctx)
    assert StatusTracker.running_partitions() == 1
    assert StatusTracker.armed?() == false
  end

  test "report alarmed partition", ctx do
    {:ok, pid, part} = start_idle_partition(ctx)
    alarm_partition(pid, part)

    assert StatusTracker.running_partitions() == 1
    TimerHelper.wait_until fn ->
      assert StatusTracker.alarmed?() == true
    end
  end

  test "report armed partition", ctx do
    {:ok, pid, part} = start_idle_partition(ctx)
    alarm_partition(pid, part)

    assert StatusTracker.running_partitions() == 1
    assert StatusTracker.armed?() == true
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
