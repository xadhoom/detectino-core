defmodule DtWeb.RuleTest do
  use DtWeb.ModelCase

  alias DtWeb.Rule

  @valid_attrs %{enabled: true, name: "some content", priority: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Rule.changeset(%Rule{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Rule.changeset(%Rule{}, @invalid_attrs)
    refute changeset.valid?
  end
end
