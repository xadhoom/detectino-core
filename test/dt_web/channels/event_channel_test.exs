defmodule DtWeb.EventChannelTest do
  use DtWeb.ChannelCase

  alias DtWeb.Channels.Event
  alias DtCore.EvRegistry

  test "can join arm topic" do
    assert {:ok, :state} = Event.join("event:arm", nil, :state)
  end

"""
  test "alarm topic listens to any alarm event" do
    {:ok, _} = Registry.start_link(:duplicate, EvRegistry.registry)

    {:ok, _, _socket} = socket()
    |> subscribe_and_join(Event, "event:alarm", %{})

    key = %{source: :partition}
    listeners = Registry.lookup(EvRegistry.registry, key)
    assert Enum.count(listeners) == 1

    key = %{source: :sensor}
    listeners = Registry.lookup(EvRegistry.registry, key)
    assert Enum.count(listeners) == 1
  end
"""

end
