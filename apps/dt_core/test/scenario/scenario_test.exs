defmodule DtCore.ScenarioTest do
  use DtCore.EctoCase

  alias DtWeb.Rule, as: RuleModel

  alias DtCore.Scenario
  alias DtCore.Handler
  alias DtCore.Event
  alias DtCore.Action

  setup do
    Action.start_link
    Handler.start_link
    :ok
  end

  def start_server do
    [ %RuleModel{expression: "if event.port > 10 then something"}, %RuleModel{expression: "if event.port < 10 then another"} ]
    |> Scenario.start_link(:some_name)
  end

  test "Init scenario" do
    {:ok, _pid} = start_server
  end

  test "Check scenario is registered" do
    {:ok, pid} = start_server
    found = Handler.get_listeners()
    |> Enum.find(fn(item) ->
        case item do
          ^pid -> true
          _ -> false
        end
      end
      )
    assert found == pid
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
    ev = %Event{address: "1234", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}
    send pid, {:event, ev}
    assert ev == Scenario.last_event(pid)
  end

  test "process rules" do
    ev = %Event{address: "1234", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}

    rules = [
      %RuleModel{expression: "if event.port == 10 then alarm", continue: false},
      %RuleModel{expression: 'if event.address == "1234" then idle', continue: false}
    ]

    state = %{
      parser: DtCore.Rule.load,
      rules: rules,
      last_event: nil
      }

    res = Scenario.process_rules(ev, state)
    assert [:alarm] == res

  end

  test "process rules with continue" do
    ev = %Event{address: "1234", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}

    rules = [
      %RuleModel{expression: "if event.port == 10 then alarm", continue: true},
      %RuleModel{expression: 'if event.address == "1234" then idle', continue: true}
    ]

    state = %{
      parser: DtCore.Rule.load,
      rules: rules,
      last_event: nil
      }

    res = Scenario.process_rules(ev, state)
    assert [:alarm, :idle] == res

  end

end
