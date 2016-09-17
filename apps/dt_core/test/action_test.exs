defmodule DtCore.ActionTest do
  use ExUnit.Case, async: true

  alias DtCore.Action
  alias DtCore.TimerHelper

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

    Action.dispatch server, [{:with_param, 'some'}]
    assert Action.last(server) == {:with_param, 'some'}
  end

  test "alarm action with timer" do
    {:ok, server} = Action.start_link

    actions = [:test, {:alarm, '0.001'}]

    Action.dispatch server, actions
    assert Action.last(server) == {:deferred, {:alarm, '0.001'}}

    TimerHelper.wait_until fn ->
      assert Action.last(server) == :alarm
    end
  end

end
