defmodule DtCore.Output.Server do
  @moduledoc """
  Server responsible of starting/stopping outputs workers.
  """
  use GenServer
  require Logger
  
  #
  # Client APIs
  #
  def start_link(sup) do
    GenServer.start_link(__MODULE__, sup, [name: :output_server])
  end

    #
  # GenServer callbacks
  #
  def init(sup) do
    Logger.info "Supervisor #{inspect sup} started Output Server"
    {:ok, %{sup: sup}}
  end

end
