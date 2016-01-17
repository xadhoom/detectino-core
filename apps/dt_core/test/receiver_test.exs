defmodule DtCore.ReceiverTest do
  use DtCore.EctoCase
  doctest DtCore

  alias DtWeb.Sensor
  alias DtCore.Receiver
  alias DtCore.Event

  test "new event raises FunctionClauseError because missing port" do
    ev = %Event{address: 10}
    assert_raise FunctionClauseError, fn -> 
      Receiver.put(ev)
    end
  end

  test "new event raises FunctionClauseError because missing address" do
    ev = %Event{port: 10}
    assert_raise FunctionClauseError, fn -> 
      Receiver.put(ev)
    end
  end

  test "new event raises FunctionClauseError because wrong port" do
    ev = %Event{address: 1234, port: "10"}
    assert_raise FunctionClauseError, fn -> 
      Receiver.put(ev)
    end
  end

  test "new event into repo" do
    ev = %Event{address: 10, port: 99}
    Receiver.put(ev)
    assert Repo.one(Sensor)
  end

  test "new event into repo, with string address" do
    refute Repo.one(Sensor)
    ev = %Event{address: "10", port: 1234}
    Receiver.put(ev)
    assert Repo.one(Sensor)
  end

  test "new event into repo is not configured" do
    refute Repo.one(Sensor)
    ev = %Event{address: 10, port: 1234}
    Receiver.put(ev)
    assert Repo.get_by(Sensor, %{configured: false})
  end

  test "new event into repo has correct address" do
    refute Repo.one(Sensor)
    ev = %Event{address: 10, port: 1234}
    Receiver.put(ev)
    assert Repo.get_by(Sensor, %{address: "10", port: 1234})
  end

end
