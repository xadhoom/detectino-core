defmodule DtWeb.SessionControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.SensorEvent
  alias DtWeb.User

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "login must not exist with GET", %{conn: conn} do
    conn = get conn, api_login_path(conn, :api_create)
    response(conn, 404)
  end

  test "fail login with no params", %{conn: conn} do
    conn = post conn, api_login_path(conn, :api_create)
    response(conn, 401)
  end

  test "fail login with invalid password", %{conn: conn} do
    create_user
    conn = post conn, api_login_path(conn, :api_create), user: %{email: "admin@local", password: "invalid"}
    response(conn, 401)
  end
  
  test "valid login", %{conn: conn} do
    create_user
    conn = post conn, api_login_path(conn, :api_create), user: %{email: "admin@local", password: "password"}
    json = json_response(conn, 200)
    assert json["token"]
  end

  defp create_user do
    encpass = Comeonin.Bcrypt.hashpwsalt("password")
    user = Repo.insert! %User{email: "admin@local", encrypted_password: encpass}
  end

end
