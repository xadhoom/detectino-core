defmodule DtWeb.SessionControllerTest do
  use DtWeb.ConnCase

  alias DtCtx.Accounts.User
  alias DtWeb.TokenServer

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "login must not be implemented with GET", %{conn: conn} do
    conn = get(conn, api_login_path(conn, :create))
    response(conn, 501)
  end

  test "fail login with no params", %{conn: conn} do
    conn = post(conn, api_login_path(conn, :create))
    response(conn, 401)
  end

  test "fail login with invalid password", %{conn: conn} do
    conn =
      post(conn, api_login_path(conn, :create),
        user: %{username: "admin@local", password: "invalid"}
      )

    response(conn, 401)
  end

  test "valid login", %{conn: conn} do
    conn =
      post(conn, api_login_path(conn, :create),
        user: %{username: "admin@local", password: "password"}
      )

    json = json_response(conn, 200)
    assert json["token"]
  end

  test "cannot refresh without a valid token", %{conn: conn} do
    conn
    |> post(api_login_path(conn, :refresh))
    |> response(401)
  end

  test "refresh token", %{conn: conn} do
    conn =
      post(conn, api_login_path(conn, :create),
        user: %{username: "admin@local", password: "password"}
      )

    json = json_response(conn, 200)
    jwt_1 = Guardian.decode_and_verify!(json["token"])
    {:ok, _} = TokenServer.get(json["token"])

    conn =
      Phoenix.ConnTest.build_conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", json["token"])
      |> post(api_login_path(conn, :refresh))

    json2 = json_response(conn, 200)
    jwt_2 = Guardian.decode_and_verify!(json2["token"])

    assert jwt_1["exp"] < jwt_2["exp"]
    # refreshing will revoke the token
    {:error, _} = TokenServer.get(json["token"])
  end

  test "cannot refresh if token is forcefully expired", %{conn: conn} do
    conn =
      post(conn, api_login_path(conn, :create),
        user: %{username: "admin@local", password: "password"}
      )

    json = json_response(conn, 200)

    # forcefully expire the token
    :ok = TokenServer.expire({:token, json["token"]})

    Phoenix.ConnTest.build_conn()
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", json["token"])
    |> post(api_login_path(conn, :refresh))
    |> response(401)

    # 401 will revoke the token
    {:error, _} = TokenServer.get(json["token"])
  end

  test "non admin role cannot invalidate sessions", %{conn: conn} do
    User.create_changeset(%User{}, %{
      name: "test",
      username: "test",
      password: "mypass",
      role: "user",
      pin: "1234"
    })
    |> Repo.insert!()

    conn =
      post(conn, api_login_path(conn, :create),
        user: %{
          username: "test",
          password: "mypass"
        }
      )

    json = json_response(conn, 200)

    Phoenix.ConnTest.build_conn()
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", json["token"])
    |> post(api_login_path(conn, :invalidate, struct(User, %{id: "1"})))
    |> response(403)
  end

  test "admin role can invalidate sessions", %{conn: conn} do
    conn =
      post(conn, api_login_path(conn, :create),
        user: %{username: "admin@local", password: "password"}
      )

    json = json_response(conn, 200)
    {:ok, token} = TokenServer.get(json["token"])

    Phoenix.ConnTest.build_conn()
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", json["token"])
    |> post(api_login_path(conn, :invalidate, struct(User, %{id: "1"})))
    |> response(204)

    assert {:error, _} = TokenServer.get(token)
  end
end
