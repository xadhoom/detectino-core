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

  def event(server, ev = %DetectorEv{}) when is_pid(server) do
    GenStateMachine.cast(server, ev)
  end

  def arm(server, exit_timeout) when is_integer(exit_timeout) do
    GenStateMachine.call(server, {:arm, exit_timeout})
  end

  #
  # GenStateMachine callbacks
  #
  def init({config = %SensorModel{}, receiver}) do
    cur_event = %DetectorEv{
      type: :idle,
      address: config.address,
      port: config.port
    }
    {:ok, :idle, %{
      config: config, receiver: receiver, last_event: cur_event
    }}
  end

  def handle_event({:call, from}, :status, state, _data) do
    {:keep_state_and_data, [{:reply, from, state}]}
  end

  #
  # :idle state callbacks
  #
  # process idle event in idle state
  def handle_event(:cast, ev = %DetectorEv{type: :idle}, :idle, data) do
    data = %{data | last_event: ev}
    {:next_state, :idle, data}
  end

  # process alarm event in idle state
  def handle_event(:cast, ev = %DetectorEv{type: :alarm}, :idle, data) do
    send data.receiver, {:stop, data.last_event}
    case data.config.full24h do
      false ->
        rt_ev = %DetectorEv{ev | type: :realtime}
        send data.receiver, {:start, rt_ev}
        {:next_state, :realtime, %{data | last_event: rt_ev}}
      true ->
        send data.receiver, {:start, ev}
        {:next_state, :alarmed, %{data | last_event: ev}}
    end
  end

  # process tamper (short) event in idle state
  def handle_event(:cast, ev = %DetectorEv{type: :short}, :idle, data) do
    send data.receiver, {:stop, %DetectorEv{ev | type: :idle}}
    send data.receiver, {:start, ev}

    {:next_state, :tampered, %{data | last_event: ev}}
  end

  # process arm request event in idle state
  def handle_event({:call, from}, {:arm, exit_timeout}, :idle, data)
    when is_integer(exit_timeout) do
    idle_ev = %DetectorEv{port: data.config.port, address: data.config.address,
      type: :idle}

    case data.config.exit_delay do
      true ->
        ex_ev = %DetectorExitEv{port: data.config.port,
          address: data.config.address}
        send data.receiver, {:stop, idle_ev}
        send data.receiver, {:start, ex_ev}
        {:next_state, :exit_wait, data, [
          {:reply, from, :ok},
          {:state_timeout, exit_timeout * 1000, :exit_wait}
          ]}
      false ->
        send data.receiver, {:start, idle_ev}
        {:next_state, :idle_arm, data, [{:reply, from, :ok}]}
    end
  end

  #
  # :tampered state callbacks
  #
  # process idle event in tampered state
  def handle_event(:cast, ev = %DetectorEv{type: :idle}, :tampered, data) do
    send data.receiver, {:stop, data.last_event}
    send data.receiver, {:start, ev}
    {:next_state, :idle, %{data | last_event: ev}}
  end

  # process tamper event in tampered state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :tampered, data)
    when type in [:tamper, :short, :fault] do
    send data.receiver, {:stop, data.last_event}
    send data.receiver, {:start, ev}
    {:next_state, :tampered, %{data | last_event: ev}}
  end

  # process alarm event in tampered state
  def handle_event(:cast, ev = %DetectorEv{type: :alarm}, :tampered, data) do
    send data.receiver, {:stop, data.last_event}
    case data.config.full24h do
      false ->
        rt_ev = %DetectorEv{ev | type: :realtime}
        send data.receiver, {:start, rt_ev}
        {:next_state, :realtime, %{data | last_event: rt_ev}}
      true ->
        send data.receiver, {:start, ev}
        {:next_state, :alarmed, %{data | last_event: ev}}
    end
  end

  #
  # :realtime state callbacks
  #
  # process tamper event in realtime state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :realtime, data)
    when type in [:tamper, :short, :fault] do
    send data.receiver, {:stop, data.last_event}
    send data.receiver, {:start, ev}
    {:next_state, :tampered, %{data | last_event: ev}}
  end

end
