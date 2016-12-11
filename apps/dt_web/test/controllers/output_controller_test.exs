defmodule DtWeb.OutputControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.ControllerHelperTest, as: Helper

  setup %{conn: conn} do
    DtWeb.ReloadRegistry.registry
    |> Registry.register(DtWeb.ReloadRegistry.key, [])
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all outputs", %{conn: conn} do
    conn = get conn, output_path(conn, :index)
    response(conn, 401)
  end

  test "create an output", %{conn: conn} do
    conn = Helper.login(conn)

    # create an output
    conn = conn
    |> post(output_path(conn, :create),
      %{name: "this is a test", type: "bus", enabled: false})
    conn |> response(401)

    conn = conn
    |> Helper.newconn
    |> put_req_header("p-dt-pin", "666666")
    |> post(output_path(conn, :create),
      %{name: "this is a test", type: "bus", enabled: false})
    json = json_response(conn, 201)
    assert json["name"] == "this is a test"

    # check that a reload event is sent
    {:reload}
    |> assert_receive(5000)

    # check that the new record is there
    conn = Helper.newconn(conn)
    |> get(output_path(conn, :index))
    response(conn, 401)

    conn = Helper.newconn(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> get(output_path(conn, :index))
    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1
  end

end
