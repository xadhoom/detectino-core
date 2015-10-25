defmodule DtBus.CanhelperTest do
  use ExUnit.Case, async: true

  alias DtBus.Canhelper, as: C

  test "command ping" do
    assert C.command(1) == :ping
    assert C.tocommand(:ping) == 1
  end

  test "command pong" do
    assert C.command(2) == :pong
    assert C.tocommand(:pong) == 2
  end

  test "command event" do
    assert C.command(3) == :event
    assert C.tocommand(:event) == 3
  end

  test "command read" do
    assert C.command(4) == :read
    assert C.tocommand(:read) == 4
  end

  test "command readd" do
    assert C.command(5) == :readd
    assert C.tocommand(:readd) == 5
  end

  test "subcommand unsolicited," do
    assert C.subcommand(0) == :unsolicited
    assert C.tosubcommand(:unsolicited) == 0
  end

  test "subcommand reply" do
    assert C.subcommand(1) == :reply
    assert C.tosubcommand(:reply) == 1
  end

  test "subcommand read all" do
    assert C.subcommand(2) == :read_all
    assert C.tosubcommand(:read_all) == 2
  end

  test "subcommand read one" do
    assert C.subcommand(4) == :read_one
    assert C.tosubcommand(:read_one) == 4
  end

  test "build message id" do
    assert C.build_msgid(33, 99, :event, :unsolicited) == 283312896
  end

  test "decode message id" do
    msgid = C.build_msgid(33, 99, :event, :unsolicited)
    assert {:ok, 33, 99, :event, :unsolicited} == C.decode_msgid(msgid)
  end

end
