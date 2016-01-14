defmodule DtWeb.SensorTypesTest do
  use DtWeb.ModelCase

  alias DtWeb.SensorTypes

  @valid_attrs %{type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = SensorTypes.changeset(%SensorTypes{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = SensorTypes.changeset(%SensorTypes{}, @invalid_attrs)
    refute changeset.valid?
  end
end
