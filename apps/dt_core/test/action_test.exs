defmodule DtCore.ActionTest do
  use ExUnit.Case, async: true

  alias DtCore.Action

  test "dispatcher client api" do
    Action.start_link

    assert_raise FunctionClauseError, fn ->
      Action.dispatch :something
    end

    Action.dispatch [:a]
    assert Action.last == :a

    Action.dispatch [:a, :b, :c]
    assert Action.last == :c

    Action.dispatch []
    assert Action.last == :c
  end

end
