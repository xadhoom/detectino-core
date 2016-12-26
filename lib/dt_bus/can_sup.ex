defmodule DtBus.CanSup do
  @moduledoc """
  CanBus Supervisor
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    children = [
      worker(DtBus.Can, []),
      worker(DtBus.CanSim, [10])
    ]
    supervise(children, strategy: :one_for_one)
  end

end
