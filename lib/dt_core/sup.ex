defmodule DtCore.Sup do
  @moduledoc """
  Root Supervisor for DtCore supervision tree.
  """
  use Supervisor
  alias DtCore.OutputsRegistry

  def start_link do
    Supervisor.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def init(_) do
    children = [
      supervisor(Registry,
        [:duplicate, OutputsRegistry.registry,
          [partitions: System.schedulers_online]],
        restart: :permanent),
      worker(DtCore.EventBridge, [], restart: :permanent),
      worker(DtCore.EventLogger, [], restart: :permanent),
      supervisor(DtCore.Monitor.Sup, [], restart: :permanent),
      supervisor(DtCore.Output.Sup, [], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_all)
  end

end
