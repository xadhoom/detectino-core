defmodule DtCore.Sensor.WorkerSup do
  @moduledoc """
  Supervisor responsible of sensors workers.
  Managed by the Sensor.Server module.
  """
  use Supervisor
  require Logger

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_) do
    Logger.info "Sensor worker supervisor up"
    supervise([], strategy: :one_for_one)
  end

end
