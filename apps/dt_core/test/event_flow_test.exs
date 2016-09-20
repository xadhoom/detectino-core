defmodule DtCore.EventFlowTest do
  use DtCore.EctoCase

  alias DtBus.Event
  alias DtCore.Handler
  alias DtCore.Receiver
  alias DtCore.Scenario
  alias DtCore.ScenarioSup
  alias DtCore.TimerHelper

  alias DtWeb.Scenario, as: ScenarioModel

  @event {:event, %Event{address: 1234, port: 10, value: "any value", type: :an_atom, subtype: :another_atom}}
  @event_normal %DtCore.Event{address: "1234", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @scenario %Scenario{name: "canemorto"}

  setup do
    Handler.start_link
    ScenarioSup.start_link

    :ok
  end
  
  test "new event gets dispatched into action handler" do
    {:ok, pid} = Receiver.start_link false

    scenario = Repo.insert!(%ScenarioModel{name: "canemorto"})
    rule = Ecto.build_assoc scenario, :rules, expression: "if event.value == \"any value\" then alarm"
    Repo.insert!(rule)

    {:ok, _pid} = ScenarioSup.start @scenario

    send pid, @event
    scenario = ScenarioSup.get_worker_by_def @scenario

    TimerHelper.wait_until fn ->  
      assert @event_normal == Scenario.last_event(scenario)
    end

    TimerHelper.wait_until fn ->  
      assert Scenario.last_action(scenario) == :alarm
    end
  end

  test "delayed alarm action" do
    {:ok, pid} = Receiver.start_link false

    scenario = Repo.insert!(%ScenarioModel{name: "canemorto"})
    rule = Ecto.build_assoc scenario, :rules, expression: "if event.value == \"any value\" then alarm(3)"
    Repo.insert!(rule)

    {:ok, _pid} = ScenarioSup.start @scenario
    send pid, @event

    scenario = ScenarioSup.get_worker_by_def @scenario
    TimerHelper.wait_until 10_000, fn ->  
      assert :alarm == Scenario.last_action(scenario)
    end
  end

  test "cancelled scenario does not fire action" do
    {:ok, pid} = Receiver.start_link false

    scenario = Repo.insert!(%ScenarioModel{name: "canemorto"})
    rule = Ecto.build_assoc scenario, :rules, expression: "if event.value == \"any value\" then alarm(2)"
    Repo.insert!(rule)

    {:ok, _pid} = ScenarioSup.start @scenario
    send pid, @event

    scenario = ScenarioSup.get_worker_by_def @scenario
    processor = Scenario.get_processor scenario
    assert GenServer.whereis(processor)

    assert :ok == ScenarioSup.stopall

    TimerHelper.wait_until fn ->  
      assert false == Process.alive? processor
    end
  end

  test "not matching filter will not go on" do
    {:ok, pid} = Receiver.start_link false

    scenario = Repo.insert!(%ScenarioModel{name: "canemorto"})
    rule = Ecto.build_assoc scenario, :rules, expression: "if event.value == \"invalid\" then alarm"
    Repo.insert!(rule)

    {:ok, _pid} = ScenarioSup.start @scenario
    send pid, @event

    scenario = ScenarioSup.get_worker_by_def @scenario
    TimerHelper.wait_until fn ->  
      assert Scenario.last_action(scenario) == :nil
    end
  end

end
