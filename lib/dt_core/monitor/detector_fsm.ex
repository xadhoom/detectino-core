defmodule DtCore.Monitor.DetectorFsm do
  @moduledoc """
  Finite State Machine for alarm detector
  """
  use GenStateMachine, callback_mode: [:handle_event_function]

  require Logger

  alias DtWeb.Sensor, as: SensorModel

  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.DetectorEntryEv

  def start_link({config = %SensorModel{}, receiver}) when is_pid(receiver) do
    GenStateMachine.start_link(__MODULE__, {config, receiver})
  end

  def status(server) do
    GenStateMachine.call(server, :status)
  end

  def event(server, ev=%DetectorEv{}) when is_pid(server) do
    GenStateMachine.cast(server, ev)
  end

  def arm(server, exit_timeout) when is_integer(exit_timeout) do
    GenStateMachine.call(server, {:arm, exit_timeout})
  end

  #
  # GenStateMachine callbacks
  #
  def init({config = %SensorModel{}, receiver}) do
    {:ok, :idle, %{config: config, receiver: receiver}}
  end

  def handle_event({:call, from}, :status, state, _data) do
    {:keep_state_and_data, [{:reply, from, state}]}
  end

  #
  # :idle state callbacks
  #
  def handle_event(:cast, _ev = %DetectorEv{type: :idle}, :idle, _data) do
    :keep_state_and_data
  end

  def handle_event(:cast, ev = %DetectorEv{type: :alarm}, :idle, data) do
    send data.receiver, {:stop, %DetectorEv{ev | type: :idle}}

    case data.config.full24h do
      false ->
        send data.receiver, {:start, %DetectorEv{ev | type: :realtime}}
        {:next_state, :realtime, data}
      true ->
        send data.receiver, {:start, ev}
        {:next_state, :alarmed, data}
    end

  end

  def handle_event(:cast, ev = %DetectorEv{type: :short}, :idle, data) do
    send data.receiver, {:stop, %DetectorEv{ev | type: :idle}}
    send data.receiver, {:start, ev}

    {:next_state, :tampered, data}
  end

  def handle_event({:call, from}, {:arm, 0}, :idle, data) do
    ev = %DetectorEv{port: data.config.port, address: data.config.address,
      type: :idle}
    send data.receiver, {:start, ev}

    {:next_state, :idle_arm, data, [{:reply, from, :ok}]}
  end

  def handle_event({:call, from}, {:arm, exit_timeout}, :idle, data)
    when exit_timeout > 0 do
    ev = %DetectorEv{port: data.config.port, address: data.config.address,
      type: :idle}
    ex_ev = %DetectorExitEv{port: data.config.port,
      address: data.config.address}
    send data.receiver, {:stop, ev}
    send data.receiver, {:start, ex_ev}

    {:next_state, :exit_wait, data, [
      {:reply, from, :ok},
      {:state_timeout, exit_timeout * 1000, :exit_wait}
      ]}
  end

end
