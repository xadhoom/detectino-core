defmodule DtCore.HandlerTest do
  use DtCore.EctoCase
  doctest DtCore

  alias DtCore.Handler
  alias DtCore.Event

  @missing_port_ev {:event, %Event{address: "10", value: "any value", type: :an_atom, subtype: :another_atom}}
  @missing_addr_ev {:event, %Event{port: 10, value: "any value", type: :an_atom, subtype: :another_atom}}
  @missing_type_ev {:event, %Event{address: "10", port: 10, value: "any value", subtype: :another_atom}}
  @missing_subtype_ev {:event, %Event{address: "10", port: 10, value: "any value", type: :an_atom}}
  @wrong_port_addr {:event, %Event{address: "1234", port: "10", value: "any value", type: :an_atom, subtype: :another_atom}}
  @wrong_addr {:event, %Event{address: 1234, port: 10, value: "any value", type: :an_atom, subtype: :another_atom}}

  @nil_value {:event, %Event{address: "1234", port: 10, type: :an_atom, subtype: :another_atom}}

  defp start_handler do
    {:ok, pid} = Handler.start_link
    ref = Process.monitor pid
    Process.unlink pid
    {:ok, ref, pid}
  end

  test "invalid events" do
    {:ok, ref, pid} = start_handler
    assert {:ok, self} == Handler.start_listening fn(_) -> raise("I should not be called") end
    send pid, @missing_port_ev
    send pid, @missing_addr_ev
    send pid, @missing_type_ev
    send pid, @missing_subtype_ev
    send pid, @wrong_addr
    send pid, @wrong_port_addr
    GenServer.stop pid, :normal
  end

  test "register listener" do
    {:ok, ref, pid} = start_handler
    assert nil == Handler.get_listener(self)
    assert {:ok, self} == Handler.start_listening()
    assert [self] == Handler.get_listeners()
    assert self == Handler.get_listener(self)
    assert {:ok, self} == Handler.stop_listening()
    assert nil == Handler.get_listener(self)
    GenServer.stop pid, :normal
  end

  test "register listener with cb and execute it" do
    ev = %Event{address: "1234", port: 10, value: "any value", type: :an_atom, subtype: :another_atom}

    {:ok, ref, pid} = start_handler
    assert {:ok, self} == Handler.start_listening fn(ev) ->
      assert %Event{} = ev
      true
    end
    send pid, {:event, ev}

    assert_receive ev, 1000
    GenServer.stop pid, :normal
  end

  test "start stop server" do
    Handler.start_link
    assert :ok == Handler.stop
  end

end

