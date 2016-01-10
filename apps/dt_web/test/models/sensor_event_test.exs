defmodule DtWeb.SensorEventTest do
  use DtWeb.ModelCase

  alias DtWeb.SensorEvent

  @valid_attrs %{subtype: "some content", type: "some content", value: "some content", uuid: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = SensorEvent.changeset(%SensorEvent{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = SensorEvent.changeset(%SensorEvent{}, @invalid_attrs)
    refute changeset.valid?
  end
end
