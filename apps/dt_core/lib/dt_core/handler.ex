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

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def put(ev = %Event{address: a, port: p,
    type: t, subtype: s, value: v}) when is_binary(a) and is_number(p) 
    and is_atom(t) and is_atom(s) and t != nil and s != nil do

    case ev.value do
      nil -> 
        Logger.debug "Dunno what to do with nil value, bailing out"
        nil
      _v -> :will_do_something_here #GenServer.call __MODULE__, {:put, ev}
    end

  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting Event Handler"
    {:ok, nil}
  end

end
