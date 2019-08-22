defmodule DtCore.Monitor.DetectorFsm do
  @moduledoc """
  Finite State Machine for alarm detector
  """
  use GenStateMachine, callback_mode: [:handle_event_function]

  alias DtCore.DetectorEntryEv
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.Monitor.Utils
  alias DtCtx.Monitoring.Sensor, as: SensorModel

  require Logger

  def start_link({config = %SensorModel{}, receiver}) when is_pid(receiver) do
    GenStateMachine.start_link(__MODULE__, {config, receiver})
  end

  def status(server) do
    GenStateMachine.call(server, :status)
  end

  def event(server, ev = %DetectorEv{}) when is_pid(server) do
    GenStateMachine.cast(server, ev)
  end

  def arm(server, timeouts = {entry_timeout, exit_timeout})
      when is_number(entry_timeout) and is_number(exit_timeout) do
    GenStateMachine.call(server, {:arm, timeouts})
  end

  def disarm(server) do
    GenStateMachine.call(server, :disarm)
  end

  #
  # GenStateMachine callbacks
  #
  def init({config = %SensorModel{}, receiver}) do
    cur_event = %DetectorEv{
      type: :idle,
      address: config.address,
      port: config.port,
      id: Utils.random_id()
    }

    {:ok, :idle,
     %{
       config: config,
       receiver: receiver,
       last_event: cur_event,
       entry_timeout: 0
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
    send(data.receiver, {:stop, data.last_event})

    case data.config.full24h do
      false ->
        rt_ev = %DetectorEv{ev | type: :realtime, id: Utils.random_id()}
        send(data.receiver, {:start, rt_ev})
        {:next_state, :realtime, %{data | last_event: rt_ev}}

      true ->
        new_ev = %DetectorEv{ev | id: Utils.random_id()}
        send(data.receiver, {:start, new_ev})
        {:next_state, :alarmed, %{data | last_event: new_ev}}
    end
  end

  # process tamper (short) event in idle state
  def handle_event(:cast, ev = %DetectorEv{type: tamper}, :idle, data)
      when tamper in [:short, :tamper, :fault] do
    send(data.receiver, {:stop, %DetectorEv{ev | type: :idle}})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})

    {:next_state, :tampered, %{data | last_event: new_ev}}
  end

  # process arm request event in idle state
  def handle_event({:call, from}, {:arm, {entry_timeout, exit_timeout}}, :idle, data)
      when is_number(entry_timeout) and is_number(exit_timeout) do
    # idle_ev = %DetectorEv{port: data.config.port, address: data.config.address,
    #  type: :idle}
    idle_ev = data.last_event

    with true <- data.config.exit_delay,
         true <- exit_timeout > 0 do
      ex_ev = %DetectorExitEv{
        port: data.config.port,
        address: data.config.address,
        id: Utils.random_id()
      }

      send(data.receiver, {:stop, idle_ev})
      send(data.receiver, {:start, ex_ev})

      {:next_state, :exit_wait, %{data | last_event: ex_ev, entry_timeout: entry_timeout},
       [
         {:reply, from, :ok},
         {:state_timeout, exit_timeout, :exit_timer_expired}
       ]}
    else
      _ ->
        new_ev = %DetectorEv{idle_ev | id: Utils.random_id()}
        send(data.receiver, {:start, new_ev})

        {:next_state, :idle_arm, %{data | entry_timeout: entry_timeout, last_event: new_ev},
         [{:reply, from, :ok}]}
    end
  end

  # process disarm request event in idle state
  def handle_event({:call, from}, :disarm, :idle, _data) do
    {:keep_state_and_data, [{:reply, from, :ok}]}
  end

  #
  # :tampered state callbacks
  #
  # process idle event in tampered state
  def handle_event(:cast, ev = %DetectorEv{type: :idle}, :tampered, data) do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :idle, %{data | last_event: new_ev}}
  end

  # process tamper event in tampered state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :tampered, data)
      when type in [:tamper, :short, :fault] do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :tampered, %{data | last_event: new_ev}}
  end

  # process alarm event in tampered state
  def handle_event(:cast, ev = %DetectorEv{type: :alarm}, :tampered, data) do
    send(data.receiver, {:stop, data.last_event})

    case data.config.full24h do
      false ->
        rt_ev = %DetectorEv{ev | type: :realtime, id: Utils.random_id()}
        send(data.receiver, {:start, rt_ev})
        {:next_state, :realtime, %{data | last_event: rt_ev}}

      true ->
        new_ev = %DetectorEv{ev | id: Utils.random_id()}
        send(data.receiver, {:start, new_ev})
        {:next_state, :alarmed, %{data | last_event: new_ev}}
    end
  end

  # process arm request event in tampered state
  def handle_event({:call, from}, {:arm, _}, :tampered, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :tripped}}]}
  end

  #
  # :realtime state callbacks
  #
  # process idle event in realtime state
  def handle_event(:cast, ev = %DetectorEv{type: :idle}, :realtime, data) do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :idle, %{data | last_event: new_ev}}
  end

  # process tamper event in realtime state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :realtime, data)
      when type in [:tamper, :short, :fault] do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :tampered, %{data | last_event: new_ev}}
  end

  # process alarm event in realtime state
  def handle_event(:cast, _ev = %DetectorEv{type: :alarm}, :realtime, _data) do
    :keep_state_and_data
  end

  # process arm request event in realtime state
  def handle_event({:call, from}, {:arm, _}, :realtime, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :tripped}}]}
  end

  # process disarm request event in realtime state
  def handle_event({:call, from}, :disarm, :realtime, _data) do
    {:keep_state_and_data, [{:reply, from, :ok}]}
  end

  #
  # :alarmed state callbacks
  #
  # process idle event in alarmed state
  def handle_event(:cast, ev = %DetectorEv{type: :idle}, :alarmed, data) do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :idle, %{data | last_event: new_ev}}
  end

  # process tamper event in alarmed state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :alarmed, data)
      when type in [:tamper, :short, :fault] do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :tampered, %{data | last_event: new_ev}}
  end

  # process alarm event in realtime state
  def handle_event(:cast, _ev = %DetectorEv{type: :alarm}, :alarmed, _data) do
    :keep_state_and_data
  end

  # process arm request event in alarmed state
  def handle_event({:call, from}, {:arm, _}, :alarmed, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :tripped}}]}
  end

  #
  # :idle_arm state callbacks
  #
  # process idle event in idle_arm state
  def handle_event(:cast, _ev = %DetectorEv{type: :idle}, :idle_arm, _data) do
    :keep_state_and_data
  end

  # process tamper event in idle_arm state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :idle_arm, data)
      when type in [:tamper, :short, :fault] do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :tampered_arm, %{data | last_event: new_ev}}
  end

  # process alarm event in idle_arm state
  def handle_event(:cast, ev = %DetectorEv{type: :alarm}, :idle_arm, data) do
    send(data.receiver, {:stop, data.last_event})

    case data.config.entry_delay do
      true ->
        en_ev = %DetectorEntryEv{
          port: data.config.port,
          address: data.config.address,
          id: Utils.random_id()
        }

        send(data.receiver, {:start, en_ev})

        {:next_state, :entry_wait, %{data | last_event: en_ev},
         [
           {:state_timeout, data.entry_timeout, :entry_timer_expired}
         ]}

      false ->
        new_ev = %DetectorEv{ev | id: Utils.random_id()}
        send(data.receiver, {:start, new_ev})
        {:next_state, :alarmed_arm, %{data | last_event: new_ev}}
    end
  end

  # process disarm request event in idle_arm state
  def handle_event({:call, from}, :disarm, :idle_arm, data) do
    # Maybe needs a new event id?
    send(data.receiver, {:start, data.last_event})
    {:next_state, :idle, data, [{:reply, from, :ok}]}
  end

  #
  # :exit_wait state callbacks
  # Note: we don't need to cancel the timer, GenStatem
  # does it for us when we receive a different event
  #
  # process idle event in exit_wait state
  def handle_event(:cast, _ev = %DetectorEv{type: :idle}, :exit_wait, _data) do
    :keep_state_and_data
  end

  # process tamper event in exit_wait state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :exit_wait, data)
      when type in [:tamper, :short, :fault] do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :tampered_arm, %{data | last_event: new_ev}}
  end

  # process alarm event in exit_wait state
  def handle_event(:cast, _ev = %DetectorEv{type: :alarm}, :exit_wait, _data) do
    :keep_state_and_data
  end

  # process timeout exit event in exit_wait state
  def handle_event(:state_timeout, :exit_timer_expired, :exit_wait, data) do
    idle_ev = %DetectorEv{
      port: data.config.port,
      address: data.config.address,
      type: :idle,
      id: Utils.random_id()
    }

    send(data.receiver, {:stop, data.last_event})
    send(data.receiver, {:start, idle_ev})
    {:next_state, :idle_arm, %{data | last_event: idle_ev}}
  end

  # process disarm request event in exit_wait state
  def handle_event({:call, from}, :disarm, :exit_wait, data) do
    idle_ev = %DetectorEv{
      port: data.config.port,
      address: data.config.address,
      type: :idle,
      id: Utils.random_id()
    }

    send(data.receiver, {:stop, data.last_event})
    send(data.receiver, {:start, idle_ev})

    {:next_state, :idle, %{data | last_event: idle_ev}, [{:reply, from, :ok}]}
  end

  #
  # :entry_wait state callbacks
  # Note: we don't need to cancel the timer, GenStatem
  # does it for us when we receive a different event
  #
  # process idle event in entry_wait state
  def handle_event(:cast, _ev = %DetectorEv{type: :idle}, :entry_wait, _data) do
    :keep_state_and_data
  end

  # process alarm event in entry_wait state
  def handle_event(:cast, _ev = %DetectorEv{type: :alarm}, :entry_wait, _data) do
    :keep_state_and_data
  end

  # process tamper event in entry_wait state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :entry_wait, data)
      when type in [:tamper, :short, :fault] do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :tampered_arm, %{data | last_event: new_ev}}
  end

  # process timeout exit event in entry_wait state
  def handle_event(:state_timeout, :entry_timer_expired, :entry_wait, data) do
    ev = %DetectorEv{
      port: data.config.port,
      address: data.config.address,
      type: :alarm,
      id: Utils.random_id()
    }

    send(data.receiver, {:stop, data.last_event})
    send(data.receiver, {:start, ev})
    {:next_state, :alarmed_arm, %{data | last_event: ev}}
  end

  # process disarm request event in entry_wait state
  def handle_event({:call, from}, :disarm, :entry_wait, data) do
    ev = %DetectorEv{
      port: data.config.port,
      address: data.config.address,
      type: :realtime,
      id: Utils.random_id()
    }

    send(data.receiver, {:stop, data.last_event})

    {next_state, ev} =
      case data.config.full24h do
        false ->
          send(data.receiver, {:start, ev})
          {:realtime, ev}

        true ->
          ev = %DetectorEv{ev | type: :alarm, id: Utils.random_id()}
          send(data.receiver, {:start, ev})
          {:alarmed, ev}
      end

    {:next_state, next_state, %{data | last_event: ev}, [{:reply, from, :ok}]}
  end

  #
  # :tampered_arm state callbacks
  #
  # process idle event in tampered_arm state
  def handle_event(:cast, _ev = %DetectorEv{type: :idle}, :tampered_arm, data) do
    ev = %DetectorEv{
      port: data.config.port,
      address: data.config.address,
      type: :idle,
      id: Utils.random_id()
    }

    send(data.receiver, {:stop, data.last_event})
    send(data.receiver, {:start, ev})
    {:next_state, :idle_arm, %{data | last_event: ev}}
  end

  # process tamper event in entry_wait state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :tampered_arm, data)
      when type in [:tamper, :short, :fault] do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:keep_state, %{data | last_event: new_ev}}
  end

  # process alarm event in tampered_arm state
  def handle_event(:cast, ev = %DetectorEv{type: :alarm}, :tampered_arm, data) do
    send(data.receiver, {:stop, data.last_event})

    case data.config.entry_delay do
      true ->
        en_ev = %DetectorEntryEv{
          port: data.config.port,
          address: data.config.address,
          id: Utils.random_id()
        }

        send(data.receiver, {:start, en_ev})

        {:next_state, :entry_wait, %{data | last_event: en_ev},
         [
           {:state_timeout, data.entry_timeout, :entry_timer_expired}
         ]}

      false ->
        new_ev = %DetectorEv{ev | id: Utils.random_id()}
        send(data.receiver, {:start, new_ev})
        {:next_state, :alarmed_arm, %{data | last_event: new_ev}}
    end
  end

  # process disarm request event in tampered_arm state
  def handle_event({:call, from}, :disarm, :tampered_arm, data) do
    # Maybe needs a new event id?
    send(data.receiver, {:start, data.last_event})
    {:next_state, :tampered, data, [{:reply, from, :ok}]}
  end

  #
  # :alarmed_arm state callbacks
  #
  # process idle event in tampered_arm state
  def handle_event(:cast, _ev = %DetectorEv{type: :idle}, :alarmed_arm, data) do
    ev = %DetectorEv{
      port: data.config.port,
      address: data.config.address,
      type: :idle,
      id: Utils.random_id()
    }

    send(data.receiver, {:stop, data.last_event})
    send(data.receiver, {:start, ev})
    {:next_state, :idle_arm, %{data | last_event: ev}}
  end

  # process tamper event in alarmed_arm state
  def handle_event(:cast, ev = %DetectorEv{type: type}, :alarmed_arm, data)
      when type in [:tamper, :short, :fault] do
    send(data.receiver, {:stop, data.last_event})
    new_ev = %DetectorEv{ev | id: Utils.random_id()}
    send(data.receiver, {:start, new_ev})
    {:next_state, :tampered_arm, %{data | last_event: new_ev}}
  end

  # process alarm event in alarmed_arm state
  def handle_event(:cast, _ev = %DetectorEv{type: :alarm}, :alarmed_arm, _data) do
    :keep_state_and_data
  end

  # process disarm request event in tampered_arm state
  def handle_event({:call, from}, :disarm, :alarmed_arm, data) do
    case data.config.full24h do
      true ->
        {:next_state, :alarmed, data,
         [
           {:reply, from, :ok}
         ]}

      false ->
        rt_ev = %DetectorEv{data.last_event | type: :realtime, id: Utils.random_id()}
        send(data.receiver, {:stop, data.last_event})
        send(data.receiver, {:start, rt_ev})

        {:next_state, :realtime, %{data | last_event: rt_ev},
         [
           {:reply, from, :ok}
         ]}
    end
  end
end
