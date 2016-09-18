defmodule DtWeb.ScenarioControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.ControllerHelperTest, as: Helper

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all scenarios", %{conn: conn} do
    conn = get conn, scenario_path(conn, :index)
    response(conn, 401)
  end

  test "auth: get all scenarios", %{conn: conn} do
    conn = login(conn)

    # create a scenario
    conn = post conn, scenario_path(conn, :create), %{name: "this is a test"}
    json = json_response(conn, 201)
    assert json["name"] == "this is a test"

    # check that the new record is there
    conn = newconn(conn)
    |> get(scenario_path(conn, :index))
    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1
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
