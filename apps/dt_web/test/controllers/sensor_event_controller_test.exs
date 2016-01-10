defmodule DtWeb.SensorEventControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.SensorEvent

  @valid_attrs %{subtype: "some content", type: "some content", value: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    token = login
    conn = put_req_header(conn, "authorization", token)
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, sensor_event_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    sensor_event = Repo.insert! %SensorEvent{uuid: UUID.uuid4()}
    conn = get conn, sensor_event_path(conn, :show, sensor_event)
    assert json_response(conn, 200)["data"] == %{"id" => sensor_event.id,
      "uuid" => sensor_event.uuid,
      "type" => sensor_event.type,
      "subtype" => sensor_event.subtype,
      "value" => sensor_event.value}
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, sensor_event_path(conn, :show, -1)
    end
  end

  test "forbis create when login is not valid", %{conn: conn} do
    conn = put_req_header(conn, "authorization", "")
    conn = post conn, sensor_event_path(conn, :create), sensor_event: @valid_attrs
    response(conn, 403)
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, sensor_event_path(conn, :create), sensor_event: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(SensorEvent, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, sensor_event_path(conn, :create), sensor_event: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    sensor_event = Repo.insert! %SensorEvent{uuid: UUID.uuid4()}
    conn = put conn, sensor_event_path(conn, :update, sensor_event), sensor_event: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(SensorEvent, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    sensor_event = Repo.insert! %SensorEvent{uuid: UUID.uuid4()}
    conn = put conn, sensor_event_path(conn, :update, sensor_event), sensor_event: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    sensor_event = Repo.insert! %SensorEvent{uuid: UUID.uuid4()}
    conn = delete conn, sensor_event_path(conn, :delete, sensor_event)
    assert response(conn, 204)
    refute Repo.get(SensorEvent, sensor_event.id)
  end

  defp login do
    conn = post conn, api_login_path(conn, :create), user: %{email: "admin@local", password: "password"}
    json = json_response(conn, 200)
    json["token"]
  end

end
