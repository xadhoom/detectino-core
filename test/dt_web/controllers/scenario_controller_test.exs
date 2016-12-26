defmodule DtWeb.ScenarioControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.User, as: UserModel
  alias DtWeb.Scenario, as: ScenarioModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtWeb.PartitionScenario, as: PartitionScenarioModel
  alias DtWeb.ControllerHelperTest, as: Helper
  alias DtWeb.ReloadRegistry

  setup %{conn: conn} do
    DtWeb.ReloadRegistry.registry
    |> Registry.register(ReloadRegistry.key, [])
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all scenarios", %{conn: conn} do
    conn = get conn, scenario_path(conn, :index)
    response(conn, 401)
  end

  test "get all scenarios that can be armed", %{conn: conn} do
    conn = Helper.login(conn)

    conn = get conn, scenario_path(conn, :get_available)
    json = json_response(conn, 200)
    assert Enum.count(json) == 0

    %ScenarioModel{name: "scenario"}
    |> Repo.insert!

    conn = conn |> Helper.newconn
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

    conn = conn |> Helper.newconn
    |> get(scenario_path(conn, :get_available))
    json = json_response(conn, 200)
    assert Enum.count(json) == 0

    scenario = %ScenarioModel{name: "scenario3", enabled: true}
    |> Repo.insert!
    partition = %PartitionModel{name: "partition2"}
    |> Repo.insert!
    %PartitionScenarioModel{
      partition_id: partition.id, scenario_id: scenario.id
    }
    |> Repo.insert!

    conn = conn |> Helper.newconn
    |> get(scenario_path(conn, :get_available))
    json = json_response(conn, 200)
    assert Enum.count(json) == 1
  end

  test "cannot arm a scenario without partitions", %{conn: conn} do
    conn = Helper.login(conn)

    scenario = %ScenarioModel{name: "scenario"}
    |> Repo.insert!

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn = conn
    |> post(scenario_path(conn, :arm, scenario))
    response(conn, 401)

    conn
    |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :arm, scenario))
    |> response(403)
  end

  test "arm a scenario", %{conn: conn} do
    conn = Helper.login(conn)

    scenario = %ScenarioModel{name: "scenario"}
    |> Repo.insert!
    partition = %PartitionModel{name: "partition", armed: "DISARM"}
    |> Repo.insert!
    %PartitionScenarioModel{
      partition_id: partition.id, scenario_id: scenario.id,
      mode: "ARM"
    }
    |> Repo.insert!

    conn = conn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :arm, scenario))
    response(conn, 401)

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "123456")
    |> post(scenario_path(conn, :arm, scenario))
    |> response(401)

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :arm, scenario), %{pin: "230477"})
    |> response(204)

    record = Repo.one(PartitionModel)
    assert record.armed == "ARM"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)
  end

  test "arm a scenario with partial modes", %{conn: conn} do
    conn = Helper.login(conn)

    scenario = %ScenarioModel{name: "scenario"}
    |> Repo.insert!
    partition = %PartitionModel{name: "partition", armed: "DISARM"}
    |> Repo.insert!

    %PartitionScenarioModel{
      partition_id: partition.id, scenario_id: scenario.id,
      mode: "ARMSTAY"
    }
    |> Repo.insert!

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :arm, scenario))
    |> response(204)

    record = Repo.one(PartitionModel)
    assert record.armed == "ARMSTAY"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)
  end

  test "arm a scenario with partial modes, but immediate", %{conn: conn} do
    conn = Helper.login(conn)

    scenario = %ScenarioModel{name: "scenario"}
    |> Repo.insert!
    partition = %PartitionModel{name: "partition", armed: "DISARM"}
    |> Repo.insert!

    %PartitionScenarioModel{
      partition_id: partition.id, scenario_id: scenario.id,
      mode: "ARMSTAYIMMEDIATE"
    }
    |> Repo.insert!

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :arm, scenario))
    |> response(204)

    record = Repo.one(PartitionModel)
    assert record.armed == "ARMSTAYIMMEDIATE"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)
  end

  test "disarm a scenario", %{conn: conn} do
    conn = Helper.login(conn)

    scenario = %ScenarioModel{name: "scenario"}
    |> Repo.insert!
    partition = %PartitionModel{name: "partition", armed: "ARM"}
    |> Repo.insert!
    %PartitionScenarioModel{
      partition_id: partition.id, scenario_id: scenario.id
    }
    |> Repo.insert!

    conn = conn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :disarm, scenario))
    response(conn, 401)

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "123456")
    |> post(scenario_path(conn, :disarm, scenario), %{pin: "123456"})
    |> response(401)

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :disarm, scenario), %{pin: "230477"})
    |> response(204)

    record = Repo.one(PartitionModel)
    assert record.armed == "DISARM"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)
  end

  test "auth: get all scenarios", %{conn: conn} do
    conn = Helper.login(conn)

    # create a scenario
    conn
    |> post(scenario_path(conn, :create), %{name: "this is a test"})
    |> response(401)

    conn = Helper.newconn(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> post(scenario_path(conn, :create), %{name: "this is a test"})
    json = json_response(conn, 201)
    assert json["name"] == "this is a test"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)

    # check that the new record is there
    conn = Helper.newconn(conn)
    |> get(scenario_path(conn, :index))
    response(conn, 401)

    conn = Helper.newconn(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> get(scenario_path(conn, :index))
    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1
  end
end
