defmodule DtWeb.TimerChannelTest do
  use DtWeb.ChannelCase

  alias DtWeb.Channels.Timer

  test "can join timer:time topic" do
    assert {:ok, :fake} = Timer.join("timer:time", nil, :fake)
    assert_received :after_join
  end

  test "time is sent over socket" do
    :meck.new(Etimer, [:passthrough])
    :meck.new(Phoenix.Channel)
    :meck.expect(Phoenix.Channel, :push,
      fn(_ , _, _) ->
        :pushed
      end)

    {:noreply, :fake} = Timer.handle_info(:after_join, :fake)

    assert :meck.called(Etimer, :start_link, :_)
    assert :meck.called(Phoenix.Channel, :push, [:fake, :_, :_])

    :meck.unload(Etimer)
    :meck.unload(Phoenix.Channel)
  end

end
