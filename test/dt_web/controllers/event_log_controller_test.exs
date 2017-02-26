defmodule DtWeb.EventLogControllerTest do
  use DtWeb.ConnCase

  alias DtCore.ArmEv
  alias DtWeb.EventLog
  alias DtWeb.ControllerHelperTest, as: Helper

  setup %{conn: conn} do
    DtWeb.ReloadRegistry.registry
    |> Registry.register(DtWeb.ReloadRegistry.key, [])
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all event logs", %{conn: conn} do
    conn = get conn, event_log_path(conn, :index)
    response(conn, 401)
  end

  test "create should not be implemented", %{conn: conn} do
    conn = Helper.login(conn)

    # create without pin should be 401
    conn = conn
    |> post(event_log_path(conn, :create), %{})
    response(conn, 401)

    # even with the pin
    Helper.newconn(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> post(event_log_path(conn, :create), %{})
    |> response(501)
  end

  test "retrieve events", %{conn: conn} do
    params = %{type: "alarm", acked: false,
      operation: "start", details: %ArmEv{}}
    EventLog.create_changeset(%EventLog{}, params)
    |> Repo.insert!

    conn = Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> get(event_log_path(conn, :index))
    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1
  end

end
