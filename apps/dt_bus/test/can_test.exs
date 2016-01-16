defmodule DtBus.CanTest do
  use ExUnit.Case, async: true
  use Bitwise

  alias DtBus.Can, as: C
  alias DtBus.CanHelper, as: CH

  test "canbus info handler" do
    fun = fn(frame) -> frame end
    state = %{myid: 0, sender_fn: fun}
    msgid = CH.build_msgid(1, 0, :event, :read_one)
    payload = <<1,2,3,4,5,6,7,8>>
    ret = {:can_frame, msgid, 8, payload, nil, nil} |> C.handle_info(state)
    assert ret == {:noreply, state}
  end

end
