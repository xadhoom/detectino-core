defmodule DtCtx.PartitionTest do
  use DtCtx.DataCase

  alias DtCtx.Monitoring.Partition

  @valid_attrs %{entry_delay: 42, exit_delay: 42, name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Partition.create_changeset(%Partition{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Partition.create_changeset(%Partition{}, @invalid_attrs)
    refute changeset.valid?
  end
end
