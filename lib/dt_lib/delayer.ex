defmodule DtLib.Delayer.Unit do
  defstruct ref: nil,
    term: nil,
    delay: nil,
    started_at: nil
end

defmodule DtLib.Delayer do
  @moduledoc """
  A simple term storage which spits back
  them after an user choosen delay.
  Each stored term has it's own delay.

  All delays must be expressed in milliseconds.
  The granularity is 10 milliseconds.
  """
  use GenServer

  alias DtLib.Delayer
  alias DtLib.Delayer.Unit

  defstruct terms: [],
    offset: 0,
    recipient: nil

  @granularity 10 # in msecs

  def start_link() do
    GenServer.start_link(__MODULE__, self())
  end

  @spec put(any(), any(), 0) :: :error
  def put(_, _, 0) do
    :error
  end

  @doc """
  put a term into my storage, I'll spit it back
  to you after the specified delay
  """
  @spec put(pid(), any(), non_neg_integer()) :: {:ok, reference()}
  def put(server, term, delay) when is_integer(delay) do
    GenServer.call(server, {:put, term, delay})
  end

  @doc false
  def tick(server) do
    GenServer.call(server, {:tick})
  end

  @doc """
  Warp my time in the future.
  Basically adds an offset (only positive) which may
  trigger events.
  Mostly used in tests.
  """
  @spec warp(pid(), non_neg_integer()) :: :warped
  def warp(server, offset) when is_integer(offset) and offset > 0 do
    GenServer.call(server, {:warp, offset})
  end

  # GenServer callbacks

  @doc false
  def init(recipient) do
    start_ticker()
    state = %Delayer{recipient: recipient}
    {:ok, state}
  end

  @doc false
  def handle_call({:warp, offset}, _from, state) do
    Etimer.stop_timer(self(), :tick)
    state = %{state | offset: offset}
    terms = process_entries(state)
    reschedule_tick()
    state = %{state | terms: terms}
    {:reply, :warped, state}
  end

  @doc false
  def handle_call({:put, term, delay}, _from, state) do
    ref = make_ref()
    entry = %Unit{ref: ref,
      term: term,
      delay: delay,
      started_at: System.monotonic_time()
    }
    terms = [entry | state.terms]
    {:reply, {:ok, ref}, %{state | terms: terms}}
  end

  @doc false
  def handle_call({:tick}, _from, state) do
    terms = process_entries(state)
    reschedule_tick()
    {:reply, :ok, %{state | terms: terms}}
  end

  defp process_entries(state) do
    Enum.reject(state.terms, fn(term) ->
      check_expired(term, state)
    end)
  end

  defp start_ticker do
    server_name = self()
    Etimer.start_link(server_name)
    reschedule_tick()
  end

  defp reschedule_tick do
    server_name = self()
    Etimer.start_timer(server_name, :tick, @granularity,
      {__MODULE__, :tick, [server_name]})
  end

  defp check_expired(term, state) do
    delay = term.delay
    now = System.monotonic_time()
    delta = System.convert_time_unit(now - term.started_at,
      :native, :millisecond)
    # we may have an offset, so apply it
    delta = delta + state.offset

    case delta do
      v when delay <= v ->
        release_term(term, state)
        true
      _ ->
        false
    end
  end

  defp release_term(term, state) do
    send(state.recipient, term.term)
  end

end
