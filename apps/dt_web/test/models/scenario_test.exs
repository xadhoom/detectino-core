defmodule DtWeb.ScenarioTest do
  use DtWeb.ModelCase

  alias DtWeb.Scenario

  @valid_attrs %{enabled: true, name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Scenario.changeset(%Scenario{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Scenario.changeset(%Scenario{}, @invalid_attrs)
    refute changeset.valid?
  end
end
