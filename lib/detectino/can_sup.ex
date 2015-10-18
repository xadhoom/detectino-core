defmodule Detectino.Sup do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    children = [worker(Detectino.Can, [])]
    supervise(children, strategy: :one_for_one)
  end

end
