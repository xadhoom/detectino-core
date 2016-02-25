defmodule DtBus.CanTest do
  use ExUnit.Case, async: true
  use Bitwise

  alias DtBus.Can, as: C
  alias DtBus.CanHelper, as: CH

  test "canbus info handler" do
    pid = case C.start_link do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end

    C.start_listening

    msgid = CH.build_msgid(1, 0, :event, :read_one)
    payload = <<1,2,3,4,5,6,7,8>>

    msg = {:can_frame, msgid, 8, payload, nil, nil}
    send pid, msg

    receive do
      ev -> assert %{event: %DtBus.Event{address: 1}}= ev
    end

  end

end
