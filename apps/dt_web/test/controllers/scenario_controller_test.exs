defmodule DtWeb.ScenarioControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.Scenario, as: ScenarioModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtWeb.PartitionScenario, as: PartitionScenarioModel
  alias DtWeb.ControllerHelperTest, as: Helper

  setup %{conn: conn} do
    DtWeb.ReloadRegistry.registry
    |> Registry.register(DtWeb.ReloadRegistry.key, [])
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all scenarios", %{conn: conn} do
    conn = get conn, scenario_path(conn, :index)
    response(conn, 401)
  end

  test "anon: get all scenarios that can be armed", %{conn: conn} do
    conn = get conn, scenario_path(conn, :get_available)
    json = json_response(conn, 200)
    assert Enum.count(json) == 0

    %ScenarioModel{name: "scenario"}
    |> Repo.insert!

    conn = Helper.newconn_anon
    |> get(scenario_path(conn, :get_available))
    json = json_response(conn, 200)
    assert Enum.count(json) == 0

    scenario = %ScenarioModel{name: "scenario2"}
    |> Repo.insert!
    partition = %PartitionModel{name: "partition"}
    |> Repo.insert!
    %PartitionScenarioModel{
      partition_id: partition.id, scenario_id: scenario.id
    }
    |> Repo.insert!

    conn = Helper.newconn_anon
    |> get(scenario_path(conn, :get_available))
    json = json_response(conn, 200)
    assert Enum.count(json) == 1
  end

  test "auth: get all scenarios", %{conn: conn} do
    conn = Helper.login(conn)

    # create a scenario
    conn = post conn, scenario_path(conn, :create), %{name: "this is a test"}
    json = json_response(conn, 201)
    assert json["name"] == "this is a test"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)

    # check that the new record is there
    conn = Helper.newconn(conn)
    |> get(scenario_path(conn, :index))
    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1
  end
end
