defmodule Dt.Bus.Sup do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    children = [worker(Dt.Bus.Can, [])]
    supervise(children, strategy: :one_for_one)
  end

end
