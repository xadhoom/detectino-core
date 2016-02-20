defmodule DtCore.ScenarioTest do
  use DtCore.EctoCase

  alias DtWeb.Rule, as: RuleModel

  alias DtCore.Scenario
  alias DtCore.Handler
  alias DtCore.Event

  setup do
    Handler.start_link
    :ok
  end

  def start_server do
    [ %RuleModel{}, %RuleModel{} ]
    |> Scenario.start_link(:some_name)
  end

  test "Init scenario" do
    {:ok, _pid} = start_server
  end

  test "Check scenario is registered" do
    {:ok, pid} = start_server
    assert [pid] == Handler.get_listeners()
  end

  test "Get Rules" do
    start_server
    rules = Scenario.get_rules(:some_name)
    assert is_list(rules)

    Enum.each(rules, fn(rule) ->
      assert %RuleModel{} = rule
    end)
  end

  test "send event" do
    {:ok, pid} = start_server
    ev = %Event{type: :test}
    send pid, {:event, ev}
    assert ev == Scenario.last_event(pid)
  end

end
