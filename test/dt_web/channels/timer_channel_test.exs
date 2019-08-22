defmodule DtWeb.TimerChannelTest do
  @moduledoc false
  use DtWeb.ChannelCase

  alias DtWeb.Channels.Timer

  test "channel pushes time" do
    {:ok, _, _socket} =
      socket(DtWeb.Sockets.Socket)
      |> subscribe_and_join(Timer, "timer:time", %{})

    assert_push("time", %{time: data})

    assert {:ok, _} = data |> Timex.parse("%Y-%m-%d %H:%M:%S", :strftime)
  end
end
