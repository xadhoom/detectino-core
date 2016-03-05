defmodule DtCore.Handler do
  @moduledoc """
  Receive an event with a value and decide what to do with the value.
  """
  use GenServer

  import Ecto.Query, only: [from: 2]

  require Logger
  alias DtCore.Event
  alias DtWeb.Repo, as: Repo
  alias DtWeb.Sensor, as: Sensor

  defstruct listeners: %{}

  @server_name :DtCoreHandler

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: @server_name)
  end

  def get_listener(pid) do
    GenServer.call(@server_name, {:get_listener, pid})
  end

  def start_listening(filter_fun \\ fn(_) -> true end) do
    GenServer.call(@server_name, {:start_listening, self, filter_fun})
  end

  def stop_listening do
    GenServer.call(@server_name, {:stop_listening, self})
  end

  def get_listeners do
    GenServer.call(@server_name, {:get_listeners})
  end

  def stop do
    GenServer.cast(@server_name, {:stop})
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting Event Handler"
    {:ok, 
      %DtCore.Handler{}
    }
  end

  def handle_call({:get_listener, pid}, _from, state) do
    key = Base.encode64 :erlang.term_to_binary(pid)
    pid = case Map.fetch(state.listeners, key) do
      :error -> nil
      {:ok, v} -> v[:pid]
    end
    {:reply, pid, state}
  end

  def handle_call({:start_listening, pid, filter_fun}, _from, state) do
    key = Base.encode64 :erlang.term_to_binary(pid)
    listeners = Map.put state.listeners, key, %{pid: pid, filter: filter_fun}
    Process.monitor pid
    {:reply, {:ok, pid}, %DtCore.Handler{state | listeners: listeners}}
  end

  def handle_call({:stop_listening, pid}, _from, state) do
    key = Base.encode64 :erlang.term_to_binary(pid)
    listeners = Map.delete state.listeners, key
    Process.unlink pid
    {:reply, {:ok, pid}, %DtCore.Handler{state | listeners: listeners}}
  end

  def handle_call({:get_listeners}, _from, state) do
    listeners = state.listeners
      |> Map.values
      |> Enum.map(fn(item) -> Map.get(item, :pid) end)
    {:reply, listeners, state}
  end

  def handle_info({:event, ev = %Event{address: a, port: p,
    type: t, subtype: s, value: v}}, state) when is_binary(a) and is_number(p) 
    and is_atom(t) and is_atom(s) and t != nil and s != nil do

    case ev.value do
      nil ->
        Logger.debug "Dunno what to do with nil value, bailing out"
      _ -> 
        Enum.each state.listeners, fn({_, v}) ->
          if v.filter.(ev) do
            send v.pid, {:event, ev}
          end
        end
    end
    {:noreply, state}
  end

  def handle_info(any, state) do
    Logger.error "Unhandled info #{inspect any}"
    {:noreply, state}
  end

  def handle_cast({:stop}, state) do
    {:stop, :normal, state}
  end

  def terminate(reason, _state) do
    Logger.info "Terminating with #{inspect reason}"
    :ok
  end

  def handle_info({:DOWN, _, _, pid, _}, state) do
    handle_call {:stop_listening, pid}, nil, state
    {:noreply, state}
  end

end
