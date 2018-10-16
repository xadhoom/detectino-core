defmodule DtCore.Monitor.Sup do
  @moduledoc """
  Supervisor responsibile of all Sensor related stuff.
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(DtCore.Monitor.Controller, [self()], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_all)
  end
end
