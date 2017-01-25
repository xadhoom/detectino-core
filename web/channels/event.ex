defmodule DtWeb.Channels.Event do
  use Phoenix.Channel

  alias DtCore.EvRegistry

  require Logger

  def join("event:arm", _message, socket) do
    {:ok, socket}
  end

  def join("event:alarm", _message, socket) do
    Registry.register(EvRegistry.registry, %{}, [])
    Registry.register(EvRegistry.registry, %{source: :sensor}, [])
    {:ok, socket}
  end

end
