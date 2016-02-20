defmodule DtCore.ReceiverTest do
  use DtCore.EctoCase

  alias DtWeb.Sensor
  alias DtCore.Receiver
  alias DtCore.Handler
  alias DtCore.Event

  @missing_port_ev %Event{address: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @missing_addr_ev %Event{port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @missing_type_ev %Event{address: 10, port: 10, value: "any value", subtype: :another_atom}
  @missing_subtype_ev %Event{address: 10, port: 10, value: "any value", type: :an_atom}
  @wrong_port_addr %Event{address: 1234, port: "10", value: "any value", type: :an_atom, subtype: :another_atom}

  @valid_ev1 %Event{address: 1234, port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @valid_ev2 %Event{address: 1235, port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @valid_ev3 %Event{address: "1235", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @valid_ev4 %Event{address: 1234, port: 11, value: "any value", type: :an_atom, subtype: :another_atom}

  setup_all do
    Handler.start_link
    Receiver.start_link(false)
    :ok
  end

  test "new event raises FunctionClauseError because missing port" do
    assert_raise FunctionClauseError, fn -> 
      Receiver.put(@missing_port_ev)
    end
  end

  test "new event raises FunctionClauseError because missing address" do
    assert_raise FunctionClauseError, fn -> 
      Receiver.put(@missing_addr_ev)
    end
  end

  test "new event raises FunctionClauseError because missing type" do
    assert_raise FunctionClauseError, fn -> 
      Receiver.put(@missing_type_ev)
    end
  end

  test "new event raises FunctionClauseError because missing subtype" do
    assert_raise FunctionClauseError, fn -> 
      Receiver.put(@missing_subtype_ev)
    end
  end

  test "new event raises FunctionClauseError because wrong port" do
    assert_raise FunctionClauseError, fn -> 
      Receiver.put(@wrong_port_addr)
    end
  end

  test "new event into repo" do
    Receiver.put(@valid_ev1)
    assert Repo.one(Sensor)
  end

  test "new event into repo, with string address" do
    refute Repo.one(Sensor)
    Receiver.put(@valid_ev3)
    assert Repo.one(Sensor)
  end

  test "new event into repo is not configured" do
    refute Repo.one(Sensor)
    Receiver.put(@valid_ev1)
    assert Repo.get_by(Sensor, %{configured: false})
  end

  test "new event into repo has correct address" do
    refute Repo.one(Sensor)
    Receiver.put(@valid_ev1)
    assert Repo.get_by(Sensor, %{address: "1234", port: 10})
  end

  test "different port results in different records" do
    refute Repo.one(Sensor)
    Receiver.put(@valid_ev1)
    Receiver.put(@valid_ev4)
    sensors = Repo.all(Sensor)
    assert 2 == length(sensors)
  end

  test "different address results in different records" do
    refute Repo.one(Sensor)
    Receiver.put(@valid_ev1)
    Receiver.put(@valid_ev2)
    sensors = Repo.all(Sensor)
    assert 2 == length(sensors)
  end

  test "same address:port results in one record" do
    refute Repo.one(Sensor)
    Receiver.put(@valid_ev1)
    Receiver.put(@valid_ev1)
    sensors = Repo.all(Sensor)
    assert 1 == length(sensors)
  end

  test "existing sensor in repo" do
    ev = %Event{address: 9999, port: 666, value: "any value", type: :an_atom, subtype: :another_atom}
    refute Repo.one(Sensor)
    Repo.insert!(%Sensor{address: "9999", port: 666, name: "a name", configured: true})
    Receiver.put(ev)
    sensors = Repo.all(Sensor)
    assert 1 == length(sensors)
  end

end
