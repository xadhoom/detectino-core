defmodule DtCore.ScenarioSupTest do
  use DtCore.EctoCase

  alias DtCore.Event
  alias DtCore.Handler
  alias DtCore.Scenario
  alias DtCore.ScenarioSup

  alias DtWeb.Scenario, as: ScenarioModel

  setup do
    Handler.start_link
    ScenarioSup.start_link
    :ok
  end

  test "Empty scenario list starts zero workers" do
    scenarios = []
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 0
  end

  test "Scenario list with same name starts one worker" do
    Repo.insert!(%ScenarioModel{name: "name"})

    scenarios = [
      %Scenario{name: "name"},
      %Scenario{name: "name"}
      ]
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 1
  end

  test "Scenario list starts workers" do
    init_repo_s1s2

    scenarios = [
      %Scenario{name: "s1"},
      %Scenario{name: "s2"}
      ]
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 2
  end

  test "Scenario list starts and stops workers" do
    init_repo_s1s2

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
    init_repo_s1s2

    s1 = %Scenario{name: "s1"}
    s2 = %Scenario{name: "s2"}
    scenarios = [s1, s2]
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 2

    assert ScenarioSup.stop(s1) == :ok
    assert ScenarioSup.running == 1
  end

  test "Scenario list starts many and stops all" do
    init_repo_s1s2

    s1 = %Scenario{name: "s1"}
    s2 = %Scenario{name: "s2"}
    scenarios = [s1, s2]
    ScenarioSup.start(scenarios)
    assert ScenarioSup.running == 2

    assert ScenarioSup.stopall() == :ok
    assert ScenarioSup.running == 0
  end

  test "Single scenario start one worker" do
    Repo.insert!(%ScenarioModel{name: "s1"})
    s1 = %Scenario{name: "s1"}
    ScenarioSup.start(s1)
    assert ScenarioSup.running == 1
  end

  test "Stop invalid worker" do
    Repo.insert!(%ScenarioModel{name: "s1"})
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
    assert id == String.to_atom("Elixir.DtCore.ScenarioSup::scenario_server_for::canemorto")
  end

  test "build child id with nil name" do
    assert_raise ArgumentError, fn -> ScenarioSup.get_child_name(%Scenario{}) end
  end

  @tag :skip
  test "put event into children" do
    scenarios = [
      %Scenario{name: "s1"},
      %Scenario{name: "s2"}
      ]

    res = %Event{} |> ScenarioSup.put
    assert {:ok, 2} = res
  end

  def init_repo_s1s2 do
    Repo.insert!(%ScenarioModel{name: "s1"})
    Repo.insert!(%ScenarioModel{name: "s2"})
  end

end
