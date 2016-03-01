defmodule DtCore.ReceiverTest do
  use DtCore.EctoCase

  alias DtWeb.Sensor
  alias DtCore.Receiver
  alias DtCore.Handler
  alias DtBus.Event

  @missing_port_ev {:event, %Event{address: 10, value: "any value", type: :an_atom, subtype: :another_atom}}
  @missing_addr_ev %Event{port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @missing_type_ev %Event{address: 10, port: 10, value: "any value", subtype: :another_atom}
  @missing_subtype_ev %Event{address: 10, port: 10, value: "any value", type: :an_atom}
  @wrong_port_addr %Event{address: 1234, port: "10", value: "any value", type: :an_atom, subtype: :another_atom}

  @valid_ev1 {:event, %Event{address: 1234, port: 10, value: "any value", type: :an_atom, subtype: :another_atom}}
  @valid_ev2 {:event, %Event{address: 1235, port: 10, value: "any value", type: :an_atom, subtype: :another_atom}}
  @valid_ev3 {:event, %Event{address: "1235", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}}
  @valid_ev4 {:event, %Event{address: 1234, port: 11, value: "any value", type: :an_atom, subtype: :another_atom}}

  setup_all do
    Handler.start_link
    :ok
  end

  defp start_receiver do
    {:ok, pid} = Receiver.start_link(false)
    ref = Process.monitor pid
    Process.unlink pid
    {:ok, ref, pid}
  end

  test "Missing port event kills server" do
    {:ok, ref, pid} = start_receiver
    send pid, @missing_port_ev
    assert_receive {:DOWN, ^ref, :process, _, {:function_clause, _any}}, 500
  end

  test "Missing address event kills server" do
    {:ok, ref, pid} = start_receiver
    send pid, @missing_addr_ev
    assert_receive {:DOWN, ^ref, :process, _, {:function_clause, _any}}, 500
  end

  test "Missing type event kills server" do
    {:ok, ref, pid} = start_receiver
    send pid, @missing_type_ev
    assert_receive {:DOWN, ^ref, :process, _, {:function_clause, _any}}, 500
  end

  test "Missing subtype event kills server" do
    {:ok, ref, pid} = start_receiver
    send pid, @missing_subtype_ev
    assert_receive {:DOWN, ^ref, :process, _, {:function_clause, _any}}, 500
  end

  test "Wrong port event kills server" do
    {:ok, ref, pid} = start_receiver
    send pid, @wrong_port_addr
    assert_receive {:DOWN, ^ref, :process, _, {:function_clause, _any}}, 500
  end

  test "new event into repo" do
    {:ok, ref, pid} = start_receiver
    send pid, @valid_ev1
    :timer.sleep 100
    assert Repo.one(Sensor)
    GenServer.stop pid, :normal
  end

  test "new event into repo, with string address" do
    refute Repo.one(Sensor)
    {:ok, ref, pid} = start_receiver
    send pid, @valid_ev3
    :timer.sleep 100
    assert Repo.one(Sensor)
    GenServer.stop pid, :normal
  end

  test "new event into repo is not configured" do
    refute Repo.one(Sensor)
    {:ok, ref, pid} = start_receiver
    send pid, @valid_ev1
    :timer.sleep 100
    assert Repo.get_by(Sensor, %{configured: false})
    GenServer.stop pid, :normal
  end

  test "new event into repo has correct address" do
    {:ok, ref, pid} = start_receiver
    refute Repo.one(Sensor)
    send pid, @valid_ev1
    :timer.sleep 100
    assert Repo.get_by(Sensor, %{address: "1234", port: 10})
    GenServer.stop pid, :normal
  end

  test "different port results in different records" do
    {:ok, ref, pid} = start_receiver
    refute Repo.one(Sensor)
    send pid, @valid_ev1
    send pid, @valid_ev4
    :timer.sleep 100
    sensors = Repo.all(Sensor)
    assert 2 == length(sensors)
    GenServer.stop pid, :normal
  end

  test "different address results in different records" do
    {:ok, ref, pid} = start_receiver
    refute Repo.one(Sensor)
    send pid, @valid_ev1
    send pid, @valid_ev2
    :timer.sleep 100
    sensors = Repo.all(Sensor)
    assert 2 == length(sensors)
    GenServer.stop pid, :normal
  end

  test "same address:port results in one record" do
    {:ok, ref, pid} = start_receiver
    refute Repo.one(Sensor)
    send pid, @valid_ev1
    send pid, @valid_ev1
    :timer.sleep 100
    sensors = Repo.all(Sensor)
    assert 1 == length(sensors)
    GenServer.stop pid, :normal
  end

  test "existing sensor in repo" do
    {:ok, ref, pid} = start_receiver
    ev = {:event, %Event{address: 9999, port: 666, value: "any value", type: :an_atom, subtype: :another_atom}}
    refute Repo.one(Sensor)
    Repo.insert!(%Sensor{address: "9999", port: 666, name: "a name", configured: true})
    send pid, ev
    sensors = Repo.all(Sensor)
    assert 1 == length(sensors)
    GenServer.stop pid, :normal
  end

end
