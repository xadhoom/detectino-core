defmodule DtWeb.SensorTest do
  use DtWeb.ModelCase

  alias DtWeb.Sensor

  @valid_attrs %{address: "some content", port: 1234}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Sensor.create_changeset(%Sensor{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Sensor.create_changeset(%Sensor{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset missing address" do
    changeset = Sensor.create_changeset(%Sensor{}, %{port: 1})
    refute changeset.valid?
  end

  test "changeset missing port" do
    changeset = Sensor.create_changeset(%Sensor{}, %{address: 1})
    refute changeset.valid?
  end

  test "uniqueness on address:port" do
    %Sensor{}
    |> Sensor.create_changeset(%{address: "10", port: 10})
    |> Repo.insert!

    sensor2 =
      %Sensor{}
      |> Sensor.create_changeset(%{address: "10", port: 10})

    assert {:error, _changeset} = Repo.insert(sensor2)

  end

end
