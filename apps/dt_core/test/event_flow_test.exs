defmodule DtCore.EventFlowTest do
  use DtCore.EctoCase

  alias DtWeb.Rule, as: RuleModel
    
  alias DtCore.Event
  alias DtCore.Handler
  alias DtCore.Receiver
  alias DtCore.Scenario
  alias DtCore.ScenarioSup

  alias DtWeb.Scenario, as: ScenarioModel

  @event %Event{address: 1234, port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @event_normal %Event{address: "1234", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @scenario %Scenario{name: "canemorto"}

  setup do
    Handler.start_link
    Receiver.start_link false
    ScenarioSup.start_link
    :ok
  end
  
  test "new event ends up into scenario last event" do

    Repo.insert!(%ScenarioModel{name: "canemorto"})
    {:ok, pid} = ScenarioSup.start @scenario

    Receiver.put @event
    scenario = ScenarioSup.get_worker_by_def @scenario

    assert @event_normal == Scenario.last_event(pid)
  end

end
