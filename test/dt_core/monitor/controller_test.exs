defmodule DtCore.Test.Monitor.Controller do
  use DtCore.EctoCase, async: false

  alias DtCore.Monitor.Sup
  alias DtCore.Monitor.Controller
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Test.TimerHelper
  alias DtWeb.ReloadRegistry
  alias DtBus.Event, as: BusEvent

  setup do
    TimerHelper.wait_until fn ->
      assert {:ok, _pid} = Sup.start_link
    end

    on_exit fn ->
      TimerHelper.wait_until fn ->
        assert Process.whereis(:sensors_controller) == nil
      end
    end
    :ok
  end

  test "One partition starts one worker (reload via client api)" do
    %PartitionModel{name: "a"}
    |> Repo.insert!

    assert :ok == Controller.reload

    TimerHelper.wait_until fn ->
      assert {:ok, 1} == Controller.partitions
    end
  end

  test "One partition starts one worker (reload via Registry msg)" do
    assert {:ok, 0} == Controller.partitions

    %PartitionModel{name: "a"}
    |> Repo.insert!

    Registry.dispatch(ReloadRegistry.registry, ReloadRegistry.key,
      fn listeners ->
        for {pid, _} <- listeners, do: send(pid, {:reload})
      end)

    TimerHelper.wait_until fn ->
      assert {:ok, 1} == Controller.partitions
    end
  end

  test "Many partitions starts many workers" do
    [%PartitionModel{name: "a"},
     %PartitionModel{name: "b"},
     %PartitionModel{name: "c"}]
    |> Enum.each(fn(part) ->
      part
      |> Repo.insert!
    end)

    assert :ok == Controller.reload

    TimerHelper.wait_until fn ->
      assert {:ok, 3} == Controller.partitions
    end
  end

  test "event from unk sensor gets cached into state" do
    assert {:ok, 0} == Controller.sensors

    ev = %BusEvent{address: "one", port: 1}
    :sensors_controller
    |> send({:event, ev})

    assert Controller.known_sensor?(ev) == true

    assert {:ok, 1} == Controller.sensors
  end

  test "not sent event is not in cache" do
    assert {:ok, 0} == Controller.sensors

    ev = %BusEvent{address: "one", port: 1}

    assert Controller.known_sensor?(ev) == false
  end

  test "event from unk sensor goes into repo" do
    assert {:ok, 0} == Controller.sensors
    assert Repo.one(SensorModel) == nil

    ev = %BusEvent{address: "one", port: 1}
    :sensors_controller
    |> send({:event, ev})

    assert {:ok, 1} == Controller.sensors

    TimerHelper.wait_until fn ->
      assert %{address: "one", port: 1} = Repo.one(SensorModel)
    end
  end

  test "many events create many record and are cached" do
    assert {:ok, 0} == Controller.sensors
    assert Repo.one(SensorModel) == nil

    [%BusEvent{address: "one", port: 1},
     %BusEvent{address: "one", port: 2},
     %BusEvent{address: "one", port: 3}]
    |> Enum.each(fn(ev) ->
      :sensors_controller
      |> send({:event, ev})

      assert Controller.known_sensor?(ev) == true
    end)

    TimerHelper.wait_until fn ->
      assert {:ok, 3} == Controller.sensors
    end

  end

  test "Server listens to reload event" do
    pid = Process.whereis(:sensors_controller)
    TimerHelper.wait_until fn ->
      listeners = Registry.keys(ReloadRegistry.registry, pid)
      assert Enum.count(listeners) == 1
    end
  end

end
