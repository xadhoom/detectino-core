defmodule DtWeb.OutputTest do
  use DtWeb.ModelCase

  alias DtWeb.Output

  @valid_attrs %{name: "some content", type: "type"}
  @invalid_attrs %{}

  test "changeset with invalid type" do
    attrs = %{name: "some content", type: "type", enabled: true}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?
  end

  test "changeset with missing enabled field" do
    attrs = %{name: "some content", type: "email"}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?
  end

  test "changeset with wrong enabled field" do
    attrs = %{name: "some content", type: "email", enabled: "wrong"}
    changeset = Output.create_changeset(%Output{}, attrs)
    refute changeset.valid?
  end

end
