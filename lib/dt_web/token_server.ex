defmodule DtWeb.TokenServer do
  @moduledoc """
  Simple memory storage for tokens
  """
  use GenServer

  require Logger

  # Client APIs
  def start_link(name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, {}, name: name)
  end

  def put(token, server \\ __MODULE__) do
    GenServer.call(server, {:put, token})
  end

  def get(token, server \\ __MODULE__) do
    GenServer.call(server, {:get, token})
  end

  def delete(token, server \\ __MODULE__) do
    GenServer.call(server, {:delete, token})
  end

  def all(server \\ __MODULE__) do
    GenServer.call(server, {:all})
  end

  # GenServer callbacks
  def init(_) do
    state = %{}
    {:ok, state}
  end

  def handle_call({:all}, _from, state) do
    {:reply, Map.keys(state), state}
  end

  def handle_call({:put, token}, _from, state) do
    now = DateTime.utc_now()
    state = Map.put(state, token, now)
    {:reply, {:ok, token}, state}
  end

  def handle_call({:get, token}, _from, state) do
    res = case Map.get(state, token) do
      nil -> {:error, :not_found}
      _ -> {:ok, token}
    end
    {:reply, res, state}
  end

  def handle_call({:delete, token}, _from, state) do
    {:reply, :ok, Map.delete(state, token)}
  end
end
