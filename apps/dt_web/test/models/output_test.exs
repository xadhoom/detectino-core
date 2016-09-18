defmodule DtWeb.OutputTest do
  use DtWeb.ModelCase

  alias DtWeb.Output

  @valid_attrs %{name: "some content", type: "type"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Output.create_changeset(%Output{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Output.create_changeset(%Output{}, @invalid_attrs)
    refute changeset.valid?
  end
end
