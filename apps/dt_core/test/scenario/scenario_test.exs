defmodule DtCore.ScenarioTest do
  use DtCore.EctoCase

  alias DtWeb.Rule, as: RuleModel

  alias DtCore.Scenario

  def start_server do
    [ %RuleModel{}, %RuleModel{} ]
    |> Scenario.start_link(:some_name)
  end

  test "Init scenario" do
    [ %RuleModel{}, %RuleModel{} ]
    |> Scenario.start_link(:some_name)
  end

  test "Get Rules" do
    start_server
    rules = Scenario.get_rules(:some_name)
    assert is_list(rules)

    Enum.each(rules, fn(rule) ->
      assert %RuleModel{} = rule
    end)
  end

  test "Put Event" do
    assert true
  end

end