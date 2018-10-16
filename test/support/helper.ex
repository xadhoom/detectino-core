defmodule DtWeb.ControllerHelperTest do
  use Phoenix.ConnTest
  import DtWeb.Router.Helpers

  @endpoint DtWeb.Endpoint

  def get_total(conn) do
    Plug.Conn.get_resp_header(conn, "x-total-count")
    |> Enum.at(0)
    |> String.to_integer()
  end

  def login(conn) do
    conn =
      post(conn, api_login_path(conn, :create),
        user: %{username: "admin@local", password: "password"}
      )

    json = json_response(conn, 200)

    Phoenix.ConnTest.build_conn()
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", json["token"])
  end

  def newconn(conn) do
    token =
      get_req_header(conn, "authorization")
      |> Enum.at(0)

    Phoenix.ConnTest.build_conn()
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", token)
  end

  def newconn_anon do
    Phoenix.ConnTest.build_conn()
    |> put_req_header("accept", "application/json")
  end
end
