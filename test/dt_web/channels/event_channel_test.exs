defmodule DtWeb.EventChannelTest do
  use DtWeb.ChannelCase, async: false

  import Supervisor.Spec

  alias DtCore.Event, as: Event
  alias DtWeb.Channels.Event, as: ChannelEvent
  alias DtCore.Sensor.Partition
  alias DtCore.Sensor.PartitionSup
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel

  test "can join arm topic" do
    assert {:ok, :state} = ChannelEvent.join("event:arm", nil, :state)
  end

  test "gets not armed status" do
    start_idle_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:arm", %{})

    assert_push "event", %{armed: false}
  end

  test "gets idle alarm status" do
    start_idle_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:alarm", %{})

    assert_push "event", %{alarmed: false}
  end

  test "gets armed status" do
    start_alarmed_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:arm", %{})

    assert_push "event", %{armed: true}
  end

  test "gets running alarm status" do
    start_alarmed_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:alarm", %{})

    assert_push "event", %{alarmed: true}
  end

  defp start_idle_partition do
    cache = :ets.new(:part_state_cache, [:set, :public])
    ctx = [cache: cache]
    start_partition(ctx)
  end

  defp start_alarmed_partition do
    cache = :ets.new(:part_state_cache, [:set, :public])
    ctx = [cache: cache]
    {:ok, pid, part} = start_partition(ctx)
    alarm_partition(pid, part)
  end

  defp alarm_partition(pid, part) do
    :ok = Partition.arm(part, "ARM")

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    ev = %Event{address: "2", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
  end

  defp start_partition(ctx) do
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

"""
  test "alarm topic listens to any alarm event" do
    {:ok, _} = Registry.start_link(:duplicate, OutputsRegistry.registry)

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(Event, "event:alarm", %{})

    key = %{source: :partition}
    listeners = Registry.lookup(OutputsRegistry.registry, key)
    assert Enum.count(listeners) == 1

    key = %{source: :sensor}
    listeners = Registry.lookup(OutputsRegistry.registry, key)
    assert Enum.count(listeners) == 1
  end
"""

end
