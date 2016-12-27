defmodule DtWeb.Channels.Event do
  use Phoenix.Channel

  require Logger

  def join("event:arm", _message, socket) do
    {:ok, socket}
  end

end
