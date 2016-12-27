defmodule DtWeb.EventChannelTest do
  use DtWeb.ChannelCase

  alias DtWeb.Channels.Event

  test "can join arm topic" do
    assert {:ok, :state} = Event.join("event:arm", nil, :state)
  end

end
