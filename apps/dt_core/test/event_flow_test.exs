defmodule DtCore.EventFlowTest do
  use DtCore.EctoCase

  alias DtBus.Event
  alias DtCore.Handler
  alias DtCore.Receiver
  alias DtCore.Scenario
  alias DtCore.ScenarioSup

  alias DtWeb.Scenario, as: ScenarioModel

  @event {:event, %Event{address: 1234, port: 10, value: "any value", type: :an_atom, subtype: :another_atom}}
  @event_normal %Event{address: "1234", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
  @scenario %Scenario{name: "canemorto"}

  setup do
    Handler.start_link
    ScenarioSup.start_link
    :ok
  end
  
  test "new event ends up into scenario last event" do
    {:ok, pid} = Receiver.start_link false

    Repo.insert!(%ScenarioModel{name: "canemorto"})
    {:ok, _pid} = ScenarioSup.start @scenario

    send pid, @event
    scenario = ScenarioSup.get_worker_by_def @scenario

    assert @event_normal == Scenario.last_event(scenario)
  end

end
