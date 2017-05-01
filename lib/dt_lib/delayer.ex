defmodule DtLib.Delayer.Unit do
  @moduledoc """
  Struct used to encapsulate requests used by DtLib.Delayer
  """
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

  @spec start_link :: {:ok, pid()}
  def start_link do
    GenServer.start_link(__MODULE__, self())
  end

  @spec put(any(), any(), 0) :: :error
  @spec put(pid(), any(), pos_integer()) :: {:ok, reference()}
  def put(_, _, 0) do
    :error
  end

  @doc """
  put a term into my storage, I'll spit it back
  to you after the specified delay.
  Returns a reference that can be used to cancel the timer later.
  """
  def put(server, term, delay) when is_integer(delay) do
    GenServer.call(server, {:put, term, delay})
  end

  @doc false
  @spec tick(pid()) :: :ok
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

  @doc """
  Cancel the timer associated to the given refernce.
  Always returns :ok, even if reference is not valid
  """
  @spec cancel(pid(), reference()) :: {:ok, any()}
  def cancel(server, ref) do
    GenServer.call(server, {:cancel, ref})
  end

  @doc """
  Stop all timers.
  """
  @spec stop_all(pid()) :: {:ok, [any(), ...]}
  def stop_all(server) do
    GenServer.call(server, {:stop_all})
  end

  # GenServer callbacks

  @doc false
  @spec init(pid()) :: {:ok, %Delayer{}}
  def init(recipient) do
    start_ticker()
    state = %Delayer{recipient: recipient}
    {:ok, state}
  end

  @doc false
  @spec handle_call({:cancel, reference()}, any(),
    %Delayer{}) :: {:reply, {:ok, any()}, %Delayer{}}
  def handle_call({:cancel, ref}, _from, state) do
    expunged = state.terms
    |> Enum.find(fn(x) ->
      ref == x.ref
    end)
    |> Map.get(:term)

    terms = state.terms
    |> Enum.reject(fn(x) ->
      ref == x.ref
    end)
    state = %{state | terms: terms}
    {:reply, {:ok, expunged}, state}
  end

  @doc false
  @spec handle_call({:stop_all}, any(),
    %Delayer{}) :: {:reply, {:ok, [any(), ...]}, %Delayer{}}
  def handle_call({:stop_all}, _from, state) do
    terms = Enum.map(state.terms, fn(x) ->
      Map.get(x, :term)
    end)
    {:reply, {:ok, terms}, %{state | terms: []}}
  end

  @doc false
  @spec handle_call({:warp}, any(),
    %Delayer{}) :: {:reply, :warped, %Delayer{}}
  def handle_call({:warp, offset}, _from, state) do
    Etimer.stop_timer(self(), :tick)
    state = %{state | offset: offset}
    terms = process_entries(state)
    reschedule_tick()

    {:reply, :warped, %{state | terms: terms}}
  end

  @doc false
  @spec handle_call({:put, any(), non_neg_integer()}, any(),
    %Delayer{}) :: {:reply, {:ok, reference()}, %Delayer{}}
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
  @spec handle_call({:tick}, any(),
    %Delayer{}) :: {:reply, :ok, %Delayer{}}
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
    offset_delta = delta + state.offset

    case offset_delta do
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
