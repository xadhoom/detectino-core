defmodule DtCore.Test.Sensor.Server do
  use DtCore.EctoCase

  alias DtCore.Sensor.Sup
  alias DtCore.Sensor.Server
  alias DtWeb.Sensor, as: SensorModel
  alias DtCore.Test.TimerHelper

  alias DtBus.Event, as: BusEvent

  setup do
    {:ok, _pid} = Sup.start_link

    on_exit fn ->
      TimerHelper.wait_until fn ->
        assert Process.whereis(:sensor_server) == nil
      end
    end

    :ok
  end

  test "One sensor starts one worker" do
    %SensorModel{name: "a", enabled: true, address: "one", port: 123}
    |> Repo.insert!

    assert :ok == Server.reload
  
    TimerHelper.wait_until fn ->
      assert {:ok, 1} == Server.workers
    end
  end

  test "Many sensors starts many workers" do
    [%SensorModel{name: "a", address: "one", port: 1},
     %SensorModel{name: "b", address: "one", port: 2},
     %SensorModel{name: "c", address: "one", port: 3}]
    |> Enum.each(fn(sensor) ->
      sensor
      |> Repo.insert!
    end)

    assert :ok == Server.reload
  
    TimerHelper.wait_until fn ->
      assert {:ok, 3} == Server.workers
    end
  end

  test "event from unk sensor gets cached into state" do
    assert {:ok, 0} == Server.workers
  
    ev = %BusEvent{address: "one", port: 1}
    :sensor_server
    |> send({:event, ev})

    assert Server.known_sensor?(ev) == true
  end

  test "not sent event is not in cache" do
    assert {:ok, 0} == Server.workers
  
    ev = %BusEvent{address: "one", port: 1}

    assert Server.known_sensor?(ev) == false
  end

  test "event from unk sensor starts new worker" do
    assert {:ok, 0} == Server.workers
  
    ev = %BusEvent{address: "one", port: 1}
    :sensor_server
    |> send({:event, ev})

    TimerHelper.wait_until fn ->
      assert {:ok, 1} == Server.workers
    end
  end

  test "event from unk sensor goes into repo" do
    assert {:ok, 0} == Server.workers
    assert Repo.one(SensorModel) == nil
  
    ev = %BusEvent{address: "one", port: 1}
    :sensor_server
    |> send({:event, ev})

    TimerHelper.wait_until fn ->
      assert %{address: "one", port: 1} = Repo.one(SensorModel)
    end
  end

  test "many events create many record and are cached" do
    assert {:ok, 0} == Server.workers
    assert Repo.one(SensorModel) == nil
  
    [%BusEvent{address: "one", port: 1},
     %BusEvent{address: "one", port: 2},
     %BusEvent{address: "one", port: 3}]
    |> Enum.each(fn(ev) ->
      :sensor_server
      |> send({:event, ev})

      assert Server.known_sensor?(ev) == true
    end)

    TimerHelper.wait_until fn ->
      assert {:ok, 3} == Server.workers
    end

  end

end
