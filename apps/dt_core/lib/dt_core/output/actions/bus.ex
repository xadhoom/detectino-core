defmodule DtCore.Output.Actions.Bus do
  @moduledoc """
  Bus action
  """
  alias DtCore.SensorEv
  alias DtCore.PartitionEv

  def trigger(ev = %SensorEv{}, config) do
  end

  def trigger(ev = %PartitionEv{}, config) do
  end
end
