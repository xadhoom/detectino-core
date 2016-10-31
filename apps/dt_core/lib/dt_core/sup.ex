defmodule DtCore.Sup do
  @moduledoc """
  Root Supervisor for DtCore supervision tree.
  """
  use Supervisor
  alias DtCore.EvRegistry

  def start_link do
    Supervisor.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def init(_) do
    children = [
      supervisor(Registry,
        [:duplicate, EvRegistry.registry,
          [partitions: System.schedulers_online]],
        restart: :permanent),
      supervisor(DtCore.Sensor.Sup, [], restart: :permanent),
      supervisor(DtCore.Output.Sup, [], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_all)
  end

end
