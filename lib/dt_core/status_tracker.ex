defmodule DtCore.StatusTracker do
  @moduledoc """
  Helper module to get alarm status on partitions and sensors.
  """
  alias DtCore.Sensor.Partition
  alias DtCore.Sensor.PartitionSup

  require Logger

  @doc "Check if any partition is on alarm"
  @spec alarmed?() :: boolean
  def alarmed? do
    Supervisor.which_children(PartitionSup)
    |> in_alarm?
  end

  @doc "Get the number of running partitions"
  @spec running_partitions() :: integer
  def running_partitions do
    ret = Supervisor.count_children(PartitionSup)
    ret.active
  end

  @doc "Returns true if any partition is armed"
  @spec armed?() :: boolean
  def armed? do
    Supervisor.which_children(PartitionSup)
    |> any_armed?
  end

  defp in_alarm?(childrens) do
    childrens
    |> Enum.any?(fn({_id, pid, _type, _modules}) ->
      case Partition.alarm_status(pid) do
        :alarm -> true
        _ -> false
      end
    end)
  end

  defp any_armed?(childrens) do
    childrens
    |> Enum.any?(fn({_id, pid, _type, _modules}) ->
      Partition.armed?(pid)
    end)
  end

end
