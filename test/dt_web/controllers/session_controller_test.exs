defmodule DtWeb.SessionControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.User

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "login must not exist with GET", %{conn: conn} do
    conn = get conn, api_login_path(conn, :create)
    response(conn, 404)
  end

  test "fail login with no params", %{conn: conn} do
    conn = post conn, api_login_path(conn, :create)
    response(conn, 401)
  end

  test "fail login with invalid password", %{conn: conn} do
    conn = post conn, api_login_path(conn, :create), user: %{username: "admin@local", password: "invalid"}
    response(conn, 401)
  end

  test "valid login", %{conn: conn} do
    conn = post conn, api_login_path(conn, :create), user: %{username: "admin@local", password: "password"}
    json = json_response(conn, 200)
    assert json["token"]
  end

  test "cannot refresh without a valid token", %{conn: conn} do
    conn
    |> post(api_login_path(conn, :refresh))
    |> response(401)
  end

  test "refresh token", %{conn: conn} do
    conn = post conn, api_login_path(conn, :create), user: %{username: "admin@local", password: "password"}
    json = json_response(conn, 200)
    jwt_1 = Guardian.decode_and_verify!(json["token"])

    conn = Phoenix.ConnTest.build_conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", json["token"])
    |> post(api_login_path(conn, :refresh))

    json = json_response(conn, 200)
    jwt_2 = Guardian.decode_and_verify!(json["token"])

    assert jwt_1["exp"] < jwt_2["exp"]
  end

  test "cannot refresh if reauth is flagged", %{conn: conn} do
    user = User.create_changeset(%User{}, %{name: "test", username: "test",
      password: "mypass", role: "admin", pin: "1234"})
    |> Repo.insert!

    conn = post conn, api_login_path(conn, :create), user: %{
      username: "test", password: "mypass"
    }
    json = json_response(conn, 200)

    User.update_changeset(user, %{id: user.id, re_auth: true})
    |> Repo.update!

    Phoenix.ConnTest.build_conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", json["token"])
    |> post(api_login_path(conn, :refresh))
    |> response(403)

    # check that we can refresh after a new login
    Phoenix.ConnTest.build_conn
    conn = post conn, api_login_path(conn, :create), user: %{
      username: "test", password: "mypass"
    }
    json = json_response(conn, 200)

    Phoenix.ConnTest.build_conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", json["token"])
    |> post(api_login_path(conn, :refresh))
    |> json_response(200)
  end

end
