defmodule DtCore.Scenario do
  use GenServer

  require Logger

  defstruct name: nil

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting Scenarios Server"
    {:ok,
      %{rules: nil}
    }
  end

end
