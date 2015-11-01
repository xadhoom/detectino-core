defmodule DtBus.CanSimTest do
  use ExUnit.Case, async: true
  use Bitwise

  alias DtBus.CanSim, as: C
  alias DtBus.CanHelper, as: CH

  test "canbus info handler" do
    fun = fn(frame) -> frame end
    state = %{myid: 0, sender_fn: fun}
    msgid = CH.build_msgid(1,0,:read,:read_t1)
    payload = <<1,2,3,4,5,6,7,8>>
    ret = {:can_frame, msgid, 8, payload, nil, nil} |> C.handle_info state
    assert ret == {:noreply, state}
  end

  test "timer callback info handler" do
    fun = fn(frame) -> frame end
    state = %{myid: 0, sender_fn: fun}
    assert {:noreply, state} == C.handle_info(:status, state)
  end

  test "ping handler" do
    fun = fn(frame) -> assert {:can_frame, 
      CH.build_msgid(0, 1, :pong, :reply),
      8, <<"DEADBEEF">>, 0, -1} == frame end

    state = %{myid: 0, sender_fn: fun}

    msgid = CH.build_msgid(1, 0, :ping, :unsolicited)
    {:can_frame, msgid, 8, <<"DEADBEEF">>, nil, nil} |> C.handle_info state
  end

  test "analog read handler" do
    fun = fn({:can_frame, msgid, 8, data, 0, -1}) -> 
      assert msgid == CH.build_msgid(0, 1, :event, :read_one)
      <<0, 0, 0, 0, 0, f, _g, _h>> =  data
      assert f == 1
    end

    state = %{myid: 0, sender_fn: fun}
    msgid = CH.build_msgid(1, 0, :read, :read_t1)
    {:can_frame, msgid, 8, <<"DEADBEEF">>, nil, nil} |> C.handle_info state
  end

end
