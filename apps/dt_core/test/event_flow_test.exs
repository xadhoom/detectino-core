defmodule DtCore.EventFlowTest do
  use DtCore.EctoCase

  alias DtBus.Event
  alias DtCore.Action
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
    Action.start_link
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
      assert Action.last == :alarm
    end

  end

  test "not matching filter will not go on" do
    {:ok, pid} = Receiver.start_link false

    scenario = Repo.insert!(%ScenarioModel{name: "canemorto"})
    rule = Ecto.build_assoc scenario, :rules, expression: "if event.value == \"invalid\" then alarm"
    Repo.insert!(rule)

    {:ok, _pid} = ScenarioSup.start @scenario
    send pid, @event

    TimerHelper.wait_until fn ->  
      assert Action.last == :nil
    end

  end

end
