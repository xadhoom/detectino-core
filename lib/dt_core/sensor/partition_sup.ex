defmodule DtCore.Sensor.PartitionSup do
  @moduledoc """
  Supervisor responsible of partitions workers.
  Managed by the Sensor.Server module.
  """
  use Supervisor
  require Logger

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_) do
    Logger.info "Partition worker supervisor up"
    supervise([], strategy: :one_for_one)
  end

end
