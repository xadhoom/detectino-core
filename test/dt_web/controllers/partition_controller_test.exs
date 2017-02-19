defmodule DtWeb.PartitionControllerTest do
  use DtWeb.ConnCase, async: false

  alias DtCore.Sensor.Partition, as: PartitionProcess
  alias DtWeb.Partition, as: PartitionModel
  alias DtWeb.ControllerHelperTest, as: Helper
  alias DtCore.Test.TimerHelper

  setup_all do
    TimerHelper.wait_until 1000, ErlangError, fn ->
      :meck.new(PartitionProcess)
      :meck.expect(PartitionProcess, :arm, fn(%PartitionModel{}, _) -> :ok end)
      :meck.expect(PartitionProcess, :disarm, fn(%PartitionModel{}, "DISARM") -> :ok end)
    end
  end

  setup %{conn: conn} do
    DtWeb.ReloadRegistry.registry
    |> Registry.register(DtWeb.ReloadRegistry.key, [])
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all partitions", %{conn: conn} do
    conn = get conn, partition_path(conn, :index)
    response(conn, 401)
  end

  test "create a partition", %{conn: conn} do
    conn = Helper.login(conn)

    # create a partition
    conn = post conn, partition_path(conn, :create),
      %{entry_delay: 42, exit_delay: 42, name: "some content"}
    response(conn, 401)

    conn = conn
    |> Helper.newconn
    |> put_req_header("p-dt-pin", "666666")
    |> post(partition_path(conn, :create),
      %{entry_delay: 42, exit_delay: 42, name: "some content"})
    json = json_response(conn, 201)
    assert json["name"] == "some content"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)

    # check that the new record is there
    conn = Helper.newconn(conn)
    |> get(partition_path(conn, :index))
    response(conn, 401)

    conn = Helper.newconn(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> get(partition_path(conn, :index))
    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1
  end

  test "disarm a partition without auth", %{conn: conn} do
    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    post(conn, partition_path(conn, :disarm, part))
    |> response(401)
  end

  test "disarm a partition with no pin", %{conn: conn} do
    conn = Helper.login(conn)

    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    post(conn, partition_path(conn, :disarm, part))
    |> response(401)
  end

  test "disarm a partition with an invalid pin", %{conn: conn} do
    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "123456")

    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    post(conn, partition_path(conn, :disarm, part))
    |> response(401)
  end

  test "arm a partition without auth", %{conn: conn} do
    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    post(conn, partition_path(conn, :arm, part))
    |> response(401)
  end

  test "arm a partition with no pin", %{conn: conn} do
    conn = Helper.login(conn)

    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    post(conn, partition_path(conn, :arm, part))
    |> response(401)
  end

  test "arm a partition with an invalid pin", %{conn: conn} do
    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "123456")

    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    post(conn, partition_path(conn, :arm, part))
    |> response(401)
  end

  test "arm an invalid partition", %{conn: conn} do
    part = %PartitionModel{id: 123, entry_delay: 42,
      exit_delay: 42, name: "some content"}

    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")

    body = %{mode: "ARM"}
    post(conn, partition_path(conn, :arm, part), body)
    |> response(404)
  end

  test "arm a partition", %{conn: conn} do
    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")

    body = %{mode: "ARM"}
    post(conn, partition_path(conn, :arm, part), body)
    |> response(204)

    part = Repo.one!(PartitionModel)
    assert part.armed == "ARM"

    assert :meck.called(PartitionProcess, :arm, [part, "ARM"])
  end

  test "arm a partition, stay mode", %{conn: conn} do
    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")

    body = %{mode: "ARMSTAY"}
    post(conn, partition_path(conn, :arm, part), body)
    |> response(204)

    part = Repo.one!(PartitionModel)
    assert part.armed == "ARMSTAY"

    assert :meck.called(PartitionProcess, :arm, [part, "ARMSTAY"])
  end

  test "arm a partition, immediate stay", %{conn: conn} do
    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")

    body = %{mode: "ARMSTAYIMMEDIATE"}
    post(conn, partition_path(conn, :arm, part), body)
    |> response(204)

    part = Repo.one!(PartitionModel)
    assert part.armed == "ARMSTAYIMMEDIATE"

    assert :meck.called(PartitionProcess, :arm, [part, "ARMSTAYIMMEDIATE"])
  end

  test "arm a partition, invalid mode", %{conn: conn} do
    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")

    body = %{mode: "TYPO"}
    post(conn, partition_path(conn, :arm, part), body)
    |> response(400)

    part = Repo.one!(PartitionModel)
    assert part.armed == nil
  end

  test "disarm a partition", %{conn: conn} do
    part = %PartitionModel{entry_delay: 42,
      exit_delay: 42, name: "some content"}
    |> Repo.insert!

    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")

    post(conn, partition_path(conn, :disarm, part))
    |> response(204)

    part = Repo.one!(PartitionModel)
    assert part.armed == "DISARM"

    assert :meck.called(PartitionProcess, :disarm, [part, "DISARM"])
  end

  test "disarm invalid partition", %{conn: conn} do
    part = %PartitionModel{id: 123, entry_delay: 42,
      exit_delay: 42, name: "some content"}

    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")

    post(conn, partition_path(conn, :disarm, part))
    |> response(404)
  end

end
