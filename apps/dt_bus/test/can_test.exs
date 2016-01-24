defmodule DtBus.CanTest do
  use ExUnit.Case, async: true
  use Bitwise

  alias DtBus.Can, as: C
  alias DtBus.CanHelper, as: CH

  test "canbus info handler" do
    msgid = CH.build_msgid(1, 0, :event, :read_one)
    payload = <<1,2,3,4,5,6,7,8>>

    pubfun = fn
      ev -> assert %DtCore.Event{address: 1} = ev
    end

    state = %{ping: %{}, publish_fn: pubfun}
    ret = {:can_frame, msgid, 8, payload, nil, nil} |> C.handle_info(state)

    assert ret == {:noreply, state}
  end

end
