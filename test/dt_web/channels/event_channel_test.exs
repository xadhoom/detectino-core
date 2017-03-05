defmodule DtWeb.EventChannelTest do
  use DtWeb.ChannelCase, async: false

  import Supervisor.Spec

  alias DtCore.Event, as: Event
  alias DtWeb.Channels.Event, as: ChannelEvent
  alias DtCore.Sensor.Partition
  alias DtCore.Sensor.PartitionSup
  alias DtCore.EventBridge
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel

  setup_all do
    {:ok, _} = Registry.start_link(:duplicate, DtCore.OutputsRegistry.registry)
    {:ok, _} = EventBridge.start_link()
    :ok
  end

  test "can join arm topic" do
    assert {:ok, :state} = ChannelEvent.join("event:arm", nil, :state)
  end

  test "gets not armed status" do
    start_idle_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:arm", %{})

    assert_push "arm", %{armed: false}
  end

  test "gets idle alarm status" do
    start_idle_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:alarm", %{})

    assert_push "alarm", %{alarmed: false}
  end

  test "gets armed status" do
    start_alarmed_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:arm", %{})

    assert_push "arm", %{armed: true}, 1000
  end

  test "gets running alarm status" do
    start_alarmed_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:alarm", %{})

    assert_push "alarm", %{alarmed: true}, 2000
  end

  test "exit timer start" do
    {_, _, part} = start_idle_partition()

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(ChannelEvent, "event:exit_timer", %{})

    :ok = Partition.arm(part, "ARM")

    assert_push "start", %{partition: "prot"}, 1000
    assert_push "stop", %{partition: "prot"}, 1000
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
    part = %PartitionModel{name: "prot", armed: "DISARM", exit_delay: 0.1,
      sensors: sensors}

    {:ok, sup_pid} = PartitionSup.start_link()

    {ret, pid} = Supervisor.start_child(sup_pid,
      worker(Partition,[{part, ctx[:cache]}],
      restart: :transient, id: part.name))

    {ret, pid, part}
  end

end
