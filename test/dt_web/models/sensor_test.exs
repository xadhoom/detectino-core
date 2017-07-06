defmodule DtWeb.SensorTest do
  use DtWeb.ModelCase

  alias DtCtx.Monitoring.Sensor

  @valid_attrs %{address: "some content", port: 1234, name: "mandatory", balance: "NC"}
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
    # this requires DB access since uniq is enforced by DB constraints 
    %Sensor{}
    |> Sensor.create_changeset(%{address: "10", port: 10, name: "a name", balance: "NC"})
    |> Repo.insert!

    sensor2 =
      %Sensor{}
      |> Sensor.create_changeset(%{address: "10", port: 10, name: "another name", balance: "NC"})

    assert {:error, _changeset} = Repo.insert(sensor2)
  end

  test "internal sensor" do
    changeset = Sensor.create_changeset(%Sensor{}, %{
      address: "some content", port: 1234, name: "mandatory", internal: true})
    assert changeset.valid?

    changeset = Sensor.create_changeset(%Sensor{}, %{
      address: "some content", port: 1234, name: "mandatory", internal: false})
    assert changeset.valid?
  end

  test "valid balance types" do
    ["NC", "NO", "EOL", "DEOL", "TEOL"]
    |> Enum.each(fn(type) ->
        changeset = Sensor.create_changeset(%Sensor{}, %{@valid_attrs | balance: type})
        assert changeset.valid?
      end)
  end

  test "invalid balance types" do
    ["some", "someother"]
    |> Enum.each(fn(type) ->
        changeset = Sensor.create_changeset(%Sensor{}, %{@valid_attrs | balance: type})
        refute changeset.valid?
      end)
  end

end
