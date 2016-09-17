defmodule DtCore.Action do
  use GenServer

  require Logger

  defstruct listeners: %{},
    last_action: nil

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def dispatch(server, actions) when is_list(actions) do
    GenServer.cast server, {:dispatch, actions}
  end

  def last(server) do
    GenServer.call server, :last
  end

  #
  # GenServer Callbacks
  #
  def init(_) do
    Logger.info "Starting Actions Dispatcher"
    {:ok, %DtCore.Action{}}
  end

  def handle_call(:last, _from, state) do
    {:reply, state.last_action, state}
  end

  def handle_cast({:dispatch, []}, state) do
    {:noreply, state}
  end

  def handle_cast({:dispatch, actions}, state) do
    last = Enum.reduce actions, :nil, fn(action, acc) ->
      router action
    end
    {:noreply, %DtCore.Action{state | last_action: last}}
  end

  def handle_info(ev = :alarm, state) do
    last = router ev
    {:noreply, %DtCore.Action{state | last_action: last}}
  end

  defp router(:alarm) do
    Logger.info "Alarm action"
    :alarm
  end

  defp router({:alarm, timer}) do
    Logger.info "Alarm action with delay"
    delay = case :string.to_float timer do
      {_, :no_float} ->
        {val, _} = :string.to_integer timer
        val
      {val, []} -> val
    end
    Process.send_after self, :alarm, trunc(delay * 1000)
    {:deferred, {:alarm, timer}}
  end

  defp router(any) do
    Logger.error "Unhandled action #{inspect any}"
    any
  end

  defp alarm do
    :alarm
  end

end
