defmodule DtWeb.SensorTest do
  use DtWeb.ModelCase

  alias DtWeb.Sensor

  @valid_attrs %{configured: true, name: "some content", node: "some content", type_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Sensor.changeset(%Sensor{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Sensor.changeset(%Sensor{}, @invalid_attrs)
    refute changeset.valid?
  end
end
