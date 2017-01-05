defmodule DtWeb.TokenServer do
  @moduledoc """
  Simple memory storage for tokens
  """
  use GenServer

  require Logger

  # Client APIs
  def start_link(name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, {name}, name: name)
  end

  def put(token, expiry, server \\ __MODULE__) do
    GenServer.call(server, {:put, token, expiry})
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

  def expire({:token, token}, server \\ __MODULE__) do
    GenServer.call(server, {:expire_token, token})
  end

  # GenServer callbacks
  def init({name}) do
    Etimer.start_link(self())
    state = %{
      tokens: %{},
      server_name: name
    }
    {:ok, state}
  end

  def handle_call({:expire_token, token}, _from, state) do
    tokens = Map.delete(state.tokens, token)
    {:reply, :ok, %{state | tokens: tokens}}
  end

  def handle_call({:all}, _from, state) do
    {:reply, Map.keys(state.tokens), state}
  end

  def handle_call({:put, token, expiry}, _from, state) do
    Etimer.start_timer(self(), token, expiry * 1000,
      {__MODULE__, :expire, [{:token, token}, state.server_name]})

    tokens = Map.put(state.tokens, token, expiry)
    {:reply, {:ok, token}, %{state | tokens: tokens}}
  end

  def handle_call({:get, token}, _from, state) do
    res = case Map.get(state.tokens, token) do
      nil -> {:error, :not_found}
      _ -> {:ok, token}
    end
    {:reply, res, state}
  end

  def handle_call({:delete, token}, _from, state) do
    tokens = Map.delete(state.tokens, token)
    {:reply, :ok, %{state | tokens: tokens}}
  end
end
