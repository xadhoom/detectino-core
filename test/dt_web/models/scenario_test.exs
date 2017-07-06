defmodule DtWeb.ScenarioTest do
  use DtWeb.ModelCase

  alias DtCtx.Monitoring.Scenario

  @valid_attrs %{enabled: true, name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Scenario.create_changeset(%Scenario{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Scenario.create_changeset(%Scenario{}, @invalid_attrs)
    refute changeset.valid?
  end
end
