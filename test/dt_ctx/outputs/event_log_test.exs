defmodule DtCtx.EventLog do
  use DtCtx.DataCase

  alias Ecto.Changeset
  alias DtCtx.Outputs.EventLog
  alias DtCore.DetectorEv
  alias DtCore.PartitionEv

  test "detector event changeset" do
    ev = %DetectorEv{id: "yadda"}
    attrs = %{type: "alarm", operation: "start",
      details: ev}

    changeset = EventLog.create_changeset(%EventLog{}, attrs)
    assert changeset.valid?

    assert Changeset.get_change(changeset, :correlation_id) == "yadda"
  end

  test "partition event changeset" do
    ev = %PartitionEv{id: "yadda"}
    attrs = %{type: "alarm", operation: "start",
      details: ev}

    changeset = EventLog.create_changeset(%EventLog{}, attrs)
    assert changeset.valid?

    assert Changeset.get_change(changeset, :correlation_id) == "yadda"
  end

end
