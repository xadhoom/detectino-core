defmodule DtWeb.PartitionControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.ControllerHelperTest, as: Helper

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

end
