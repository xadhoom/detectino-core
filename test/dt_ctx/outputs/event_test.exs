defmodule DtCtx.EventTest do
  use DtCtx.DataCase

  alias DtCtx.Outputs.Event

  test "changeset with invalid source" do
    attrs = %{name: "a name", source: "whatever"}
    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
  end

  test "changeset with valid source, no config" do
    attrs = %{name: "a name", source: "sensor"}
    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
  end

  test "malformed source config" do
    attrs = %{name: "name", source: "partition", source_config: "aye"}
    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
  end

  test "changeset for a partition event" do
    sconf =
      %{name: "a name", type: "alarm"}
      |> Jason.encode!()

    attrs = %{name: "name", source: "partition", source_config: sconf}
    changeset = Event.create_changeset(%Event{}, attrs)
    assert changeset.valid?
  end

  test "changeset for a partition event: missing type" do
    sconf =
      %{name: "a name"}
      |> Jason.encode!()

    attrs = %{name: "name", source: "partition", source_config: sconf}
    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
  end

  test "changeset for a partition event: missing name" do
    sconf =
      %{type: "alarm"}
      |> Jason.encode!()

    attrs = %{name: "name", source: "partition", source_config: sconf}
    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
  end

  test "changeset for a sensor event" do
    sconf =
      %{address: "1", port: 1, type: "alarm"}
      |> Jason.encode!()

    attrs = %{name: "name", source: "sensor", source_config: sconf}
    changeset = Event.create_changeset(%Event{}, attrs)
    assert changeset.valid?
  end

  test "changeset for a sensor event: missing address" do
    sconf =
      %{port: 1, type: "alarm"}
      |> Jason.encode!()

    attrs = %{name: "name", source: "sensor", source_config: sconf}
    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
  end

  test "changeset for a sensor event: missing port" do
    sconf =
      %{address: "1", type: "alarm"}
      |> Jason.encode!()

    attrs = %{name: "name", source: "sensor", source_config: sconf}
    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
  end

  test "changeset for a sensor event: missing type" do
    sconf =
      %{address: "1", port: 1}
      |> Jason.encode!()

    attrs = %{name: "name", source: "sensor", source_config: sconf}
    changeset = Event.create_changeset(%Event{}, attrs)
    refute changeset.valid?
  end
end
