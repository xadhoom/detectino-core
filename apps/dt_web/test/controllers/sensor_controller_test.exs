defmodule DtWeb.SensorControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtWeb.PartitionSensor, as: PartitionSensorModel
  alias DtWeb.ControllerHelperTest, as: Helper

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all sensors", %{conn: conn} do
    conn = get conn, sensor_path(conn, :index)
    response(conn, 401)
  end

  test "create a sensor", %{conn: conn} do
    conn = login(conn)

    # create a sensor
    conn = post conn, sensor_path(conn, :create), %{name: "this is a test", address: "10", port: 10}
    json = json_response(conn, 201)
    assert json["name"] == "this is a test"

    # check that the new record is there
    conn = newconn(conn)
    |> get(sensor_path(conn, :index))
    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1
  end

  test "get all sensors", %{conn: conn} do
    [%SensorModel{name: "a", address: "one", port: 1},
     %SensorModel{name: "b", address: "one", port: 2},
     %SensorModel{name: "c", address: "one", port: 3}]
    |> Enum.each(fn(sensor) ->
      sensor
      |> Repo.insert!
    end)

    conn = login(conn)
    |> get(sensor_path(conn, :index))
    json = json_response(conn, 200)

    assert Enum.count(json) == 3

    total = Helper.get_total(conn)
    assert total == 3
  end

  test "add partitions to a sensor", %{conn: conn} do
    conn = login(conn)

    # create a sensor
    conn = post conn, sensor_path(conn, :create), %{name: "sensor", address: "10", port: 10}
    sensor = json_response(conn, 201)

    # create a partition
    conn = newconn(conn)
    |> post(partition_path(conn, :create), %{name: "area", exit_delay: 42, entry_delay: 42})
    partition = json_response(conn, 201)

    data = sensor
    |> Map.put("partitions", [partition])

    conn = newconn(conn)
    |> put(sensor_path(conn, :update, struct(SensorModel, %{id: sensor["id"]})), data)
    sensor = json_response(conn, 200)

    Repo.one!(PartitionModel)

    join = Repo.one!(PartitionSensorModel)
    assert join.sensor_id == sensor["id"]
    assert join.partition_id == partition["id"]

  end

  defp login(conn) do
    conn = post conn, api_login_path(conn, :create), user: %{username: "admin@local", password: "password"}
    json = json_response(conn, 200)

    Phoenix.ConnTest.build_conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", json["token"])
  end

  defp newconn(conn) do
    token = get_req_header(conn, "authorization")
    |> Enum.at(0)

    Phoenix.ConnTest.build_conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", token)
  end
end
