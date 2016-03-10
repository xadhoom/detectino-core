defmodule DtCore.Action do
  use GenServer

  require Logger

  defstruct listeners: %{},
    last_action: nil

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def dispatch(actions) when is_list(actions) do
    GenServer.cast __MODULE__, {:dispatch, actions}
  end

  def last do
    GenServer.call __MODULE__, :last
  end

  #
  # GenServer Callbacks
  #
  def init(_) do
    {:ok, %DtCore.Action{}}
  end

  def handle_call(:last, _from, state) do
    {:reply, state.last_action, state}
  end

  def handle_cast({:dispatch, []}, state) do
    {:noreply, state}
  end

  def handle_cast({:dispatch, actions}, state) do
    last = Enum.reduce actions, fn(action, last_item) ->
      case action do
        :alarm -> Logger.info "Alarm action"
        _  -> Logger.info "Catchall action"
      end
      action
    end
    {:noreply, %DtCore.Action{state | last_action: last}}
  end

end
