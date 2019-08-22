defmodule DtCtx.EventLog do
  @moduledoc false
  use DtCtx.DataCase

  alias DtCore.DetectorEv
  alias DtCore.PartitionEv
  alias DtCtx.Outputs.EventLog
  alias Ecto.Changeset

  test "detector event changeset" do
    ev = %DetectorEv{id: "yadda"}
    attrs = %{type: "alarm", operation: "start", details: ev}

    changeset = EventLog.create_changeset(%EventLog{}, attrs)
    assert changeset.valid?

    assert Changeset.get_change(changeset, :correlation_id) == "yadda"
  end

  test "partition event changeset" do
    ev = %PartitionEv{id: "yadda"}
    attrs = %{type: "alarm", operation: "start", details: ev}

    changeset = EventLog.create_changeset(%EventLog{}, attrs)
    assert changeset.valid?

    assert Changeset.get_change(changeset, :correlation_id) == "yadda"
  end
end
