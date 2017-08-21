defmodule DtWeb.ScenarioControllerTest do
  use DtWeb.ConnCase

  alias DtCtx.Accounts.User, as: UserModel
  alias DtCtx.Monitoring.Scenario, as: ScenarioModel
  alias DtCtx.Monitoring.Partition, as: PartitionModel
  alias DtCtx.Monitoring.PartitionScenario, as: PartitionScenarioModel
  alias DtWeb.ControllerHelperTest, as: Helper
  alias DtWeb.ReloadRegistry
  alias DtCore.Monitor.Partition, as: PartitionProcess
  alias DtCore.Test.TimerHelper

  setup_all do
    TimerHelper.wait_until 1000, ErlangError, fn ->
      :meck.new(PartitionProcess)
      :meck.expect(PartitionProcess, :arm, fn(%PartitionModel{}, _, _) -> :ok end)
      :meck.expect(PartitionProcess, :disarm, fn(%PartitionModel{}, _) -> :ok end)
    end
  end

  setup %{conn: conn} do
    DtWeb.ReloadRegistry.registry
    |> Registry.register(ReloadRegistry.key, [])
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all scenarios", %{conn: conn} do
    conn = get conn, scenario_path(conn, :index)
    response(conn, 401)
  end

  test "get all scenarios that can be run", %{conn: conn} do
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

  test "cannot run a scenario without partitions", %{conn: conn} do
    conn = Helper.login(conn)

    scenario = %ScenarioModel{name: "scenario"}
    |> Repo.insert!

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn = conn
    |> post(scenario_path(conn, :run, scenario))
    response(conn, 401)

    conn
    |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :run, scenario))
    |> response(403)
  end

  test "run a scenario with an ARM partition", %{conn: conn} do
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
    |> post(scenario_path(conn, :run, scenario))
    response(conn, 401)

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "123456")
    |> post(scenario_path(conn, :run, scenario))
    |> response(401)

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :run, scenario), %{pin: "230477"})
    |> response(204)

    record = Repo.one(PartitionModel)
    assert record.armed == "ARM"

    assert :meck.called(PartitionProcess, :arm, [record, :_, "ARM"])
  end

  test "run a scenario with partial modes", %{conn: conn} do
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
    |> post(scenario_path(conn, :run, scenario))
    |> response(204)

    record = Repo.one(PartitionModel)
    assert record.armed == "ARMSTAY"

    assert :meck.called(PartitionProcess, :arm, [record, :_, "ARMSTAY"])
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
    |> post(scenario_path(conn, :run, scenario))
    |> response(204)

    record = Repo.one(PartitionModel)
    assert record.armed == "ARMSTAYIMMEDIATE"

    assert :meck.called(PartitionProcess, :arm, [record, :_, "ARMSTAYIMMEDIATE"])
  end

  test "run a scenario with disarm partition", %{conn: conn} do
    conn = Helper.login(conn)

    scenario = %ScenarioModel{name: "scenario"}
    |> Repo.insert!
    partition = %PartitionModel{name: "partition", armed: "ARM"}
    |> Repo.insert!
    %PartitionScenarioModel{
      partition_id: partition.id, scenario_id: scenario.id,
      mode: "DISARM"
    }
    |> Repo.insert!

    conn = conn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :run, scenario))
    response(conn, 401)

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "123456")
    |> post(scenario_path(conn, :run, scenario), %{pin: "123456"})
    |> response(401)

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :run, scenario), %{pin: "230477"})
    |> response(204)

    record = Repo.one(PartitionModel)
    assert record.armed == "DISARM"

    assert :meck.called(PartitionProcess, :disarm, [record, :_])
  end

  test "run a scenario with mixed modes", %{conn: conn} do
    conn = Helper.login(conn)

    scenario = %ScenarioModel{name: "scenario"}
    |> Repo.insert!
    partition1 = %PartitionModel{name: "partition1", armed: "DISARM"}
    |> Repo.insert!
    partition2 = %PartitionModel{name: "partition2", armed: "DISARM"}
    |> Repo.insert!
    partition3 = %PartitionModel{name: "partition3", armed: "DISARM"}
    |> Repo.insert!
    partition4 = %PartitionModel{name: "partition4", armed: "DISARM"}
    |> Repo.insert!

    %PartitionScenarioModel{
      partition_id: partition1.id, scenario_id: scenario.id,
      mode: "DISARM"}
    |> Repo.insert!
    %PartitionScenarioModel{
      partition_id: partition2.id, scenario_id: scenario.id,
      mode: "ARM"}
    |> Repo.insert!
    %PartitionScenarioModel{
      partition_id: partition3.id, scenario_id: scenario.id,
      mode: "ARMSTAY"}
    |> Repo.insert!
    %PartitionScenarioModel{
      partition_id: partition4.id, scenario_id: scenario.id,
      mode: "ARMSTAYIMMEDIATE"}
    |> Repo.insert!

    %UserModel{username: "test@local", pin: "230477"}
    |> Repo.insert!

    conn |> Helper.newconn
    |> put_req_header("p-dt-pin", "230477")
    |> post(scenario_path(conn, :run, scenario))
    |> response(204)

    records = Repo.all(PartitionModel)
    assert Enum.any?(records, fn(x) -> x.armed == "DISARM" end)
    assert Enum.any?(records, fn(x) -> x.armed == "ARM" end)
    assert Enum.any?(records, fn(x) -> x.armed == "ARMSTAY" end)
    assert Enum.any?(records, fn(x) -> x.armed == "ARMSTAYIMMEDIATE" end)

    assert :meck.called(PartitionProcess, :disarm, [:_, :_])
    assert :meck.called(PartitionProcess, :arm, [:_, :_, "ARM"])
    assert :meck.called(PartitionProcess, :arm, [:_, :_, "ARMSTAY"])
    assert :meck.called(PartitionProcess, :arm, [:_, :_, "ARMSTAYIMMEDIATE"])
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
