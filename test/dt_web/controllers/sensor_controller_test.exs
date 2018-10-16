defmodule DtWeb.SensorControllerTest do
  use DtWeb.ConnCase

  alias DtCtx.Monitoring.Sensor, as: SensorModel
  alias DtCtx.Monitoring.Partition, as: PartitionModel
  alias DtCtx.Monitoring.PartitionSensor, as: PartitionSensorModel
  alias DtWeb.ControllerHelperTest, as: Helper

  setup %{conn: conn} do
    DtWeb.ReloadRegistry.registry()
    |> Registry.register(DtWeb.ReloadRegistry.key(), [])

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all sensors", %{conn: conn} do
    conn = get(conn, sensor_path(conn, :index))
    response(conn, 401)
  end

  test "create a sensor", %{conn: conn} do
    conn = Helper.login(conn)

    # create a sensor
    conn =
      post(conn, sensor_path(conn, :create), %{name: "this is a test", address: "10", port: 10})

    response(conn, 401)

    conn =
      conn
      |> Helper.newconn()
      |> put_req_header("p-dt-pin", "666666")
      |> post(
        sensor_path(conn, :create),
        %{name: "this is a test", address: "10", port: 10}
      )

    json = json_response(conn, 201)
    assert json["name"] == "this is a test"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)

    # check that the new record is there
    conn =
      Helper.newconn(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> get(sensor_path(conn, :index))

    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1
  end

  test "get all sensors", %{conn: conn} do
    [
      %SensorModel{name: "a", address: "one", port: 1},
      %SensorModel{name: "b", address: "one", port: 2},
      %SensorModel{name: "c", address: "one", port: 3}
    ]
    |> Enum.each(fn sensor ->
      sensor
      |> Repo.insert!()
    end)

    conn =
      Helper.login(conn)
      |> get(sensor_path(conn, :index))

    response(conn, 401)

    conn =
      Helper.login(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> get(sensor_path(conn, :index))

    json = json_response(conn, 200)

    assert Enum.count(json) == 3

    total = Helper.get_total(conn)
    assert total == 3
  end

  test "add partitions to a sensor", %{conn: conn} do
    conn = Helper.login(conn)

    # create a sensor
    conn =
      conn
      |> put_req_header("p-dt-pin", "666666")
      |> post(
        sensor_path(conn, :create),
        %{name: "sensor", address: "10", port: 10}
      )

    sensor = json_response(conn, 201)

    # create a partition
    conn =
      conn
      |> Helper.newconn()
      |> put_req_header("p-dt-pin", "666666")
      |> post(
        partition_path(conn, :create),
        %{name: "area", exit_delay: 42, entry_delay: 42}
      )

    partition = json_response(conn, 201)

    data =
      sensor
      |> Map.put("partitions", [partition])

    conn =
      conn
      |> Helper.newconn()
      |> put(sensor_path(conn, :update, struct(SensorModel, %{id: sensor["id"]})), data)

    response(conn, 401)

    conn =
      conn
      |> Helper.newconn()
      |> put_req_header("p-dt-pin", "666666")
      |> put(sensor_path(conn, :update, struct(SensorModel, %{id: sensor["id"]})), data)

    sensor = json_response(conn, 200)

    Repo.one!(PartitionModel)

    join = Repo.one!(PartitionSensorModel)
    assert join.sensor_id == sensor["id"]
    assert join.partition_id == partition["id"]
  end
end
