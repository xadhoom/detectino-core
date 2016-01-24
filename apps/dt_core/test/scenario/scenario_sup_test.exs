defmodule DtCore.ScenarioSupTest do
  use DtCore.EctoCase

  alias DtCore.Scenario
  alias DtCore.ScenarioSup

  setup do
    ScenarioSup.start_link
    :ok
  end

  test "Empty scenario list starts zero workers" do
    scenarios = []
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 0
  end

  test "Scenario list with same name starts one worker" do
    scenarios = [
      %Scenario{name: "name"},
      %Scenario{name: "name"}
      ]
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 1
  end

  test "Scenario list starts workers" do
    scenarios = [
      %Scenario{name: "s1"},
      %Scenario{name: "s2"}
      ]
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 2
  end

  test "Scenario list starts and stops workers" do
    scenarios = [
      %Scenario{name: "s1"},
      %Scenario{name: "s2"}
      ]
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 2

    ScenarioSup.stop(scenarios)
    assert ScenarioSup.running == 0
  end

  test "Scenario list starts many and stops one worker" do
    s1 = %Scenario{name: "s1"}
    s2 = %Scenario{name: "s2"}
    scenarios = [s1, s2]
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 2

    assert ScenarioSup.stop(s1) == :ok
    assert ScenarioSup.running == 1
  end

  test "Scenario list start one worker" do
    s1 = %Scenario{name: "s1"}
    ScenarioSup.start(s1)
    assert ScenarioSup.running == 1
  end

  test "Stop invalid worker" do
    s1 = %Scenario{name: "s1"}
    assert {:error, :not_found} = ScenarioSup.stop(s1)
    assert ScenarioSup.running == 0
  end

  test "Stop invalid workers" do
    scenarios = [
      %Scenario{name: "s1"},
      %Scenario{name: "s2"}
      ]
    assert :ok = ScenarioSup.stop(scenarios)
    assert ScenarioSup.running == 0
  end

  test "build child id" do
    id = ScenarioSup.get_child_name(%Scenario{name: "canemorto"})
    assert id == "Elixir.DtCore.ScenarioSup::scenario_server_for::canemorto"
  end

  test "build child id with nil name" do
    assert_raise ArgumentError, fn -> ScenarioSup.get_child_name(%Scenario{}) end
  end

end
