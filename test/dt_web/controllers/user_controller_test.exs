defmodule DtWeb.UserControllerTest do
  use DtWeb.ConnCase

  alias DtCtx.Accounts.User
  alias DtWeb.ControllerHelperTest, as: Helper

  @valid_attrs %{
    username: "test@local",
    email: "some content",
    role: "some content",
    name: "some content",
    password: "some content",
    pin: "123456"
  }

  @missing_username %{
    email: "some content",
    encrypted_password: "some content",
    name: "some content",
    password: "some content"
  }

  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "anon: get all users", %{conn: conn} do
    conn = get(conn, user_path(conn, :index))
    response(conn, 401)
  end

  test "auth: get all users", %{conn: conn} do
    conn =
      Helper.login(conn)
      |> get(user_path(conn, :index))

    response(conn, 401)

    conn =
      Helper.newconn(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> get(user_path(conn, :index))

    json = json_response(conn, 200)

    assert Enum.count(json) == 1

    total = Helper.get_total(conn)
    assert total == 1

    first = Enum.at(json, 0)
    assert first["username"] == "admin@local"
  end

  test "auth: get one user", %{conn: conn} do
    conn =
      Helper.login(conn)
      |> get(user_path(conn, :show, struct(User, %{id: "1"})))

    response(conn, 401)

    conn =
      Helper.newconn(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> get(user_path(conn, :show, struct(User, %{id: "1"})))

    json = json_response(conn, 200)
    assert json["username"] == "admin@local"
  end

  test "auth: get not existent user", %{conn: conn} do
    conn =
      Helper.login(conn)
      |> get(user_path(conn, :show, struct(User, %{id: "2"})))

    response(conn, 401)

    Helper.newconn(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> get(user_path(conn, :show, struct(User, %{id: "2"})))
    |> response(404)
  end

  test "auth: save one user", %{conn: conn} do
    conn =
      Helper.login(conn)
      |> post(user_path(conn, :create), @valid_attrs)

    response(conn, 401)

    conn =
      Helper.newconn(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> post(user_path(conn, :create), @valid_attrs)

    json = json_response(conn, 201)
    assert json["username"] == "test@local"

    location =
      get_resp_header(conn, "location")
      |> Enum.at(0)

    assert location == "/api/users/" <> Integer.to_string(json["id"])
  end

  test "auth: save a duplicated user", %{conn: conn} do
    attrs = %{
      username: "admin@local",
      email: "some content",
      role: "some content",
      name: "some content",
      password: "some content"
    }

    Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> post(user_path(conn, :create), attrs)
    |> json_response(400)
  end

  test "auth: save one invalid user", %{conn: conn} do
    conn =
      Helper.login(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> post(user_path(conn, :create), @invalid_attrs)

    json_response(conn, 400)

    Helper.newconn(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> post(user_path(conn, :create), @missing_username)
    |> json_response(400)
  end

  test "auth: update one user", %{conn: conn} do
    u = Repo.one!(User)
    assert u.username == "admin@local"

    params = Map.put(@valid_attrs, "id", "1")

    conn =
      Helper.login(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> put(user_path(conn, :update, struct(User, %{id: "1"})), params)

    json = json_response(conn, 200)
    assert json["username"] == "test@local"

    u = Repo.one!(User)
    assert u.username == "test@local"

    cnt =
      Repo.all(User)
      |> Enum.count()

    assert cnt == 1
  end

  test "auth: update invalid user", %{conn: conn} do
    u = Repo.one!(User)
    assert u.username == "admin@local"

    params = Map.put(@valid_attrs, "id", "2")

    Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> put(user_path(conn, :update, struct(User, %{id: "2"})), params)
    |> response(404)

    u = Repo.one!(User)
    assert u.username == "admin@local"
  end

  test "auth: delete admin user", %{conn: conn} do
    Helper.login(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> delete(user_path(conn, :delete, struct(User, %{id: "1"})))
    |> response(403)
  end

  test "auth: delete an user", %{conn: conn} do
    conn =
      Helper.login(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> post(user_path(conn, :create), @valid_attrs)

    json = json_response(conn, 201)

    Helper.newconn(conn)
    |> put_req_header("p-dt-pin", "666666")
    |> delete(user_path(conn, :delete, struct(User, %{id: json["id"]})))
    |> response(204)
  end

  test "pin is validated", %{conn: conn} do
    conn =
      conn
      |> post(user_path(conn, :check_pin), %{pin: "123456"})

    response(conn, 401)

    conn =
      Helper.newconn_anon()
      |> Helper.login()
      |> post(user_path(conn, :check_pin), %{pin: "123456"})

    response(conn, 404)

    conn =
      Helper.newconn(conn)
      |> put_req_header("p-dt-pin", "666666")
      |> post(user_path(conn, :create), @valid_attrs)

    conn =
      Helper.newconn(conn)
      |> post(user_path(conn, :check_pin), %{pin: "123456"})

    response(conn, 200)

    conn =
      Helper.newconn(conn)
      |> post(user_path(conn, :check_pin), %{pin: "666666"})

    response(conn, 200)
  end

  test "pin check return it's expiry value", %{conn: conn} do
    conn =
      conn
      |> Helper.login()
      |> post(user_path(conn, :check_pin), %{pin: "666666"})

    json = json_response(conn, 200)

    assert json["expire"] == 60_000
  end
end
