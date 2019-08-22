defmodule DtWeb.EventChannelTest do
  @moduledoc false
  use DtWeb.ChannelCase

  alias DtCore.Event, as: Event
  alias DtCore.Monitor.{Controller, Partition}
  alias DtCore.{EventBridge, EventLogger}
  alias DtCore.Monitor.Sup, as: MonitorSup
  alias DtCore.Test.TimerHelper
  alias DtCtx.Monitoring.Partition, as: PartitionModel
  alias DtCtx.Monitoring.Sensor, as: SensorModel
  alias DtWeb.Channels.Event, as: ChannelEvent

  setup_all do
    {:ok, _} = Registry.start_link(keys: :duplicate, name: DtCore.OutputsRegistry.registry())
    {:ok, _} = EventBridge.start_link()
    :ok
  end

  setup do
    {:ok, _} = MonitorSup.start_link()

    on_exit(fn ->
      TimerHelper.wait_until(fn ->
        assert Process.whereis(DtCore.Monitor.Sup) == nil
      end)
    end)

    :ok
  end

  test "can join arm topic" do
    assert {:ok, :state} = ChannelEvent.join("event:arm", nil, :state)
  end

  test "gets not armed status" do
    start_idle_partition()

    {:ok, _, _socket} =
      build_socket()
      |> subscribe_and_join(ChannelEvent, "event:arm", %{})

    assert_push("arm", %{armed: false})
  end

  test "gets idle alarm status" do
    start_idle_partition()

    {:ok, _, _socket} =
      build_socket()
      |> subscribe_and_join(ChannelEvent, "event:alarm", %{})

    assert_push("alarm", %{alarmed: false})
  end

  test "gets armed status" do
    start_alarmed_partition()

    {:ok, _, _socket} =
      build_socket()
      |> subscribe_and_join(ChannelEvent, "event:arm", %{})

    assert_push("arm", %{armed: true}, 1000)
  end

  test "gets running alarm status" do
    start_alarmed_partition()

    {:ok, _, _socket} =
      build_socket()
      |> subscribe_and_join(ChannelEvent, "event:alarm", %{})

    assert_push("alarm", %{alarmed: true}, 2000)
  end

  test "exit timer start" do
    {:ok, part} = start_idle_partition()

    {:ok, _, _socket} =
      build_socket()
      |> subscribe_and_join(ChannelEvent, "event:exit_timer", %{})

    :ok = Partition.arm(part, "foo")

    assert_push("start", %{partition: "prot"}, 5000)
    assert_push("stop", %{partition: "prot"}, 5000)
  end

  test "gets unacked alarm events" do
    {:ok, _} = EventLogger.start_link()

    start_alarmed_partition()

    {:ok, _, _socket} =
      build_socket()
      |> subscribe_and_join(ChannelEvent, "event:alarm_events", %{})

    assert_push("alarm_events", %{events: 3}, 5000)
  end

  defp start_idle_partition do
    start_partition()
  end

  defp start_alarmed_partition do
    {:ok, part} = start_partition()

    :ok = Partition.arm(part, "foo")

    Controller.get_sensors()
    |> Enum.each(fn pid ->
      ev = %Event{address: "1", port: 1, value: 15}
      :ok = Process.send(pid, {:event, ev}, [])
      ev = %Event{address: "2", port: 1, value: 15}
      :ok = Process.send(pid, {:event, ev}, [])
    end)
  end

  defp start_partition do
    sensors = [
      %SensorModel{
        name: "A",
        balance: "NC",
        th1: 10,
        partitions: [],
        enabled: true,
        address: "1",
        port: 1
      },
      %SensorModel{
        name: "B",
        balance: "NC",
        th1: 10,
        partitions: [],
        enabled: true,
        address: "2",
        port: 1
      }
    ]

    part = %PartitionModel{
      name: "prot",
      armed: "DISARM",
      exit_delay: 1,
      entry_delay: 0,
      sensors: sensors
    }

    :ok = Controller.reload({sensors, [part]})

    {:ok, part}
  end

  defp build_socket do
    socket(DtWeb.Sockets.Socket)
  end
end
