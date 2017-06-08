defmodule DtCore.StatusTracker do
  @moduledoc """
  Helper module to get alarm status on partitions and sensors.
  """
  alias DtCore.Monitor.Partition
  alias DtCore.Monitor.Controller

  require Logger

  @doc "Check if any partition is on alarm"
  @spec alarmed?() :: boolean
  def alarmed? do
    Controller.get_partitions() |> in_alarm?
  end

  @doc "Get the number of running partitions"
  @spec running_partitions() :: integer
  def running_partitions do
    Controller.partitions()
  end

  @doc "Returns true if any partition is armed"
  @spec armed?() :: boolean
  def armed? do
    Controller.get_partitions() |> any_armed?
  end

  defp in_alarm?(pids) do
    pids
    |> Enum.any?(fn(pid) ->
      case Partition.alarm_status(pid) do
        :alarm -> true
        _ -> false
      end
    end)
  end

  defp any_armed?(pids) do
    pids
    |> Enum.any?(fn(pid) ->
      Partition.armed?(pid)
    end)
  end

end
