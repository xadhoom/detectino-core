defmodule DtBus.CanhelperTest do
  use ExUnit.Case, async: true

  test "command ping" do
    assert DtBus.Canhelper.command(1) == :ping
  end

  test "command pong" do
    assert DtBus.Canhelper.command(2) == :pong
  end

  test "command event" do
    assert DtBus.Canhelper.command(3) == :event
  end

  test "command read" do
    assert DtBus.Canhelper.command(4) == :read
  end

  test "command readd" do
    assert DtBus.Canhelper.command(5) == :readd
  end

  test "subcommand unsolicited," do
    assert DtBus.Canhelper.subcommand(0) == :unsolicited
  end

  test "subcommand reply" do
    assert DtBus.Canhelper.subcommand(1) == :reply
  end

  test "subcommand read all" do
    assert DtBus.Canhelper.subcommand(2) == :read_all
  end

  test "subcommand read one" do
    assert DtBus.Canhelper.subcommand(4) == :read_one
  end

end
