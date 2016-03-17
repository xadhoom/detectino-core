defmodule DtCore.ActionTest do
  use ExUnit.Case, async: true

  alias DtCore.Action

  test "dispatcher client api" do
    {:ok, server} = Action.start_link

    assert_raise FunctionClauseError, fn ->
      Action.dispatch server, :something
    end

    Action.dispatch server, [:a]
    assert Action.last(server) == :a

    Action.dispatch server, [:a, :b, :c]
    assert Action.last(server) == :c

    Action.dispatch server, []
    assert Action.last(server) == :c
  end

end
