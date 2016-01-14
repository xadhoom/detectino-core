defmodule DtCore.Event do
  defstruct from: nil,
    type: nil,
    subtype: nil,
    port: nil,
    value: nil
end

defmodule DtCore.Receiver do
  use GenServer

  require Logger
  alias DtCore.Event

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def put(event = %Event{}) do
    GenServer.call __MODULE__, {:put, event}
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting Event Receiver"
    {:ok, nil}
  end

  def handle_call({:put, event = %Event{}}, from, state) do
    Logger.debug "Got event " <> inspect(event)

    {:reply, nil, state}
  end

end
