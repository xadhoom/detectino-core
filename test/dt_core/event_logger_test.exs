defmodule DtCore.Test.EventLoggerTest do
  @moduledoc false
  use DtCtx.DataCase

  alias DtCore.ArmEv
  alias DtCore.DetectorEv
  alias DtCore.EventBridge
  alias DtCore.EventLogger
  alias DtCore.ExitTimerEv
  alias DtCore.Monitor.Utils
  alias DtCore.PartitionEv
  alias DtCore.Test.TimerHelper
  alias DtCtx.Outputs.EventLog

  setup_all do
    {:ok, _} = Registry.start_link(keys: :duplicate, name: DtCore.OutputsRegistry.registry())
    {:ok, _} = EventBridge.start_link()
    :ok
  end

  setup do
    {:ok, _} = EventLogger.start_link()
    :ok
  end

  test "receives and saves an arm event" do
    {:start, %ArmEv{name: "test", partial: false, id: "yadda", initiator: "foo"}} |> dispatch()

    log = Repo.one!(EventLog)

    assert log.type == "arm"
    assert log.acked == true
    assert log.operation == "start"
    assert log.details["ev"]["partial"] == false
  end

  test "receives and saves a stop arm event" do
    {:stop, %ArmEv{name: "test", partial: false, id: "yadda", initiator: "foo"}} |> dispatch()

    log = Repo.one!(EventLog)

    assert log.operation == "stop"
  end

  test "receives and saves an alarm event from a sensor" do
    {:start, %DetectorEv{type: :short, id: Utils.random_id()}}
    |> dispatch()

    log = Repo.one!(EventLog)

    assert log.type == "alarm"
    assert log.acked == false
    assert log.operation == "start"
    assert log.details["ev"]["type"] == "short"
  end

  test "receives and saves a stop alarm event from a sensor" do
    {:stop, %DetectorEv{type: :short, id: Utils.random_id()}}
    |> dispatch()

    log = Repo.one!(EventLog)

    assert log.operation == "stop"
  end

  test "receives and saves an alarm event from a partition" do
    {:start, %PartitionEv{type: :short, id: Utils.random_id()}}
    |> dispatch()

    log = Repo.one!(EventLog)

    assert log.type == "alarm"
    assert log.acked == false
    assert log.operation == "start"
    assert log.details["ev"]["type"] == "short"
  end

  test "receives and saves a stop alarm event from a partition" do
    {:stop, %PartitionEv{type: :short, id: Utils.random_id()}}
    |> dispatch()

    log = Repo.one!(EventLog)

    assert log.operation == "stop"
  end

  test "receives and saves an event from exit timer" do
    {:stop, %ExitTimerEv{name: "42", id: Utils.random_id()}}
    |> dispatch()

    log = Repo.one!(EventLog)

    assert log.type == "exit_timer"
    assert log.operation == "stop"
    assert log.details["ev"]["name"] == "42"
  end

  test "receives and saves a stop event from exit timer" do
    {:stop, %ExitTimerEv{name: "42", id: Utils.random_id()}}
    |> dispatch()

    log = Repo.one!(EventLog)

    assert log.operation == "stop"
  end

  defp dispatch(ev) do
    EventBridge.dispatch(%{}, ev)

    TimerHelper.wait_until(1000, Ecto.NoResultsError, fn ->
      # all async here, may not be on db immediately
      Repo.one!(EventLog)
    end)
  end
end
