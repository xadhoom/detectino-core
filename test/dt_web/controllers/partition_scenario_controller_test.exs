defmodule DtWeb.PartitionScenarioControllerTest do
  @moduledoc false
  use DtWeb.ConnCase

  alias DtCtx.Monitoring.Partition, as: PartitionModel
  alias DtCtx.Monitoring.PartitionScenario, as: PartitionScenarioModel
  alias DtCtx.Monitoring.Scenario, as: ScenarioModel
  alias DtWeb.ControllerHelperTest, as: Helper

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all partitions", %{conn: conn} do
    conn = get(conn, scenario_partition_scenario_path(conn, :index, 1))
    response(conn, 401)
  end

  test "get associated scenarios", %{conn: conn} do
    scenario =
      %ScenarioModel{name: "scenario3", enabled: true}
      |> Repo.insert!()

    partition =
      %PartitionModel{name: "partition2"}
      |> Repo.insert!()

    %PartitionScenarioModel{
      partition_id: partition.id,
      scenario_id: scenario.id
    }
    |> Repo.insert!()

    conn =
      conn
      |> Helper.login()
      |> put_req_header("p-dt-pin", "666666")
      |> get(scenario_partition_scenario_path(conn, :index, scenario.id))

    json = json_response(conn, 200)
    assert Enum.count(json) == 1
  end
end
