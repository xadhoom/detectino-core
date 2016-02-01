defmodule DtCore.ScenarioLoaderTest do
  use DtCore.EctoCase

  alias DtWeb.Scenario, as: ScenarioModel

  alias DtCore.ScenarioLoader
  alias DtCore.ScenarioSup

  setup do
    ScenarioSup.start_link
    :ok
  end

  test "One scenario starts one server" do
    Repo.insert! %ScenarioModel{name: "canemorto", enabled: true}
    ScenarioLoader.initialize

    assert ScenarioSup.running == 1
  end

  test "Many scenarios starts many server" do
    Repo.insert! %ScenarioModel{name: "canemorto", enabled: true}
    Repo.insert! %ScenarioModel{name: "canemorto2", enabled: true}
    ScenarioLoader.initialize

    assert ScenarioSup.running == 2
  end

  test "Disabled scenario starts nothing" do
    Repo.insert! %ScenarioModel{name: "canemorto", enabled: false}
    ScenarioLoader.initialize

    assert ScenarioSup.running == 0
  end

  test "Call initialize multiple times" do
    Repo.insert! %ScenarioModel{name: "canemorto", enabled: true}
    ScenarioLoader.initialize

    assert ScenarioSup.running == 1

    ScenarioLoader.initialize
    assert ScenarioSup.running == 1
  end

end
