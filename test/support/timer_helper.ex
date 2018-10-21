defmodule DtCore.Test.TimerHelper do
  @moduledoc """
  Utility to check assertion for a while
  """
  def wait_until(fun), do: wait_until(1000, fun)

  def wait_until(0, fun), do: fun.()

  def wait_until(timeout, fun) do
    wait_until(timeout, ExUnit.AssertionError, fun)
  end

  def wait_until(0, _exception, fun), do: fun.()

  def wait_until(timeout, exception, fun) do
    try do
      fun.()
    rescue
      error ->
        name = error.__struct__
        stack = System.stacktrace()

        case name do
          ^exception ->
            :timer.sleep(10)
            wait_until(max(0, timeout - 10), exception, fun)

          _name ->
            reraise(error, stack)
        end
    end
  end
end
