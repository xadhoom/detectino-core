defmodule DtWeb.EventTest do
  use DtWeb.ModelCase

  alias DtWeb.Event

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Event.create_changeset(%Event{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Event.create_changeset(%Event{}, @invalid_attrs)
    refute changeset.valid?
  end
end
