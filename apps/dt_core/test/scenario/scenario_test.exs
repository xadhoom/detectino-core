defmodule DtCore.ScenarioTest do
  use DtCore.EctoCase

  alias DtWeb.Rule, as: RuleModel

  alias DtCore.Scenario
  alias DtCore.Handler

  def start_server do
    Handler.start_link
    [ %RuleModel{}, %RuleModel{} ]
    |> Scenario.start_link(:some_name)
  end

  test "Init scenario" do
    Handler.start_link
    [ %RuleModel{}, %RuleModel{} ]
    |> Scenario.start_link(:some_name)
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

  @tag :skip
  test "Put Event" do
    start_server
    Scenario.put
  end

end
