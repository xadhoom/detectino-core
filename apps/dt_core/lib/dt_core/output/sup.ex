defmodule DtCore.Output.Sup do
  @moduledoc """
  Supervisor responsibile of all Outputs related stuff.
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def init(_) do
    children = [
      worker(DtCore.Output.Server, [self()], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_all)
  end

end
