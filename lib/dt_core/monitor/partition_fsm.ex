defmodule DtCore.Monitor.PartitionFsm do
  @moduledoc """
  Finite State Machine for alarm partition (aka zones)
  """
  use GenStateMachine, callback_mode: [:handle_event_function]

  alias DtCore.ArmEv
  alias DtCore.ExitTimerEv
  alias DtCore.DetectorEv
  alias DtCore.PartitionEv
  alias DtCore.Monitor.Detector
  alias DtWeb.Partition, as: PartitionModel

  require Logger

  def start_link({config = %PartitionModel{}, receiver}) when is_pid(receiver) do
    GenStateMachine.start_link(__MODULE__, {config, receiver})
  end

  def event(server, ev = {:start, _ = %DetectorEv{}}) when is_pid(server) do
    GenStateMachine.cast(server, ev)
  end

  def event(server, _ = {:stop, _ = %DetectorEv{}}) when is_pid(server) do
    #
    # noop here, we don't care about stopping, since the
    # partition fsm works only with start events from sensros
    #
  end

  def arm(server) do
    GenStateMachine.call(server, {:arm, false, 0})
  end

  def arm(server, exit_timeout) when is_integer(exit_timeout) do
    GenStateMachine.call(server, {:arm, :normal, exit_timeout})
  end

  def arm(server, mode, exit_timeout)
    when mode in [:stay, :immediate] and is_integer(exit_timeout) do
    GenStateMachine.call(server, {:arm, mode, exit_timeout})
  end

  def disarm(server) do
    GenStateMachine.call(server, :disarm)
  end

  def status(server) do
    GenStateMachine.call(server, :status)
  end

  #
  # GenStateMachine callbacks
  #
  def init({config = %PartitionModel{}, receiver}) do
    {:ok, :idle, %{
      config: config,
      receiver: receiver,
      tampered: [],
      alarmed: []}
    }
  end

  def handle_event({:call, from}, :status, state, _data) do
    {:keep_state_and_data, [{:reply, from, state}]}
  end

  #
  # :idle/:idle_arm state callbacks
  #
  # process idle event in idle/idle_arm state
  def handle_event(:cast, {_ , _ = %DetectorEv{type: :idle}}, idle, _data)
    when idle in [:idle, :idle_arm] do
    :keep_state_and_data
  end

  # process tamper event in idle/idle_arm state
  def handle_event(:cast, {_ , dev = %DetectorEv{type: tamper}}, idle, data)
    when tamper in [:short, :tamper, :fault] and idle in [:idle, :idle_arm] do
    pev = build_partition_ev(:tamper, data.config)
    send data.receiver, {:start, pev}
    data = add_tripped(:tampered, dev, data)
    {:next_state, :tripped, data}
  end

  # process realtime event in idle state
  def handle_event(:cast, {_ , dev = %DetectorEv{type: :realtime}}, :idle, data) do
    data = drop_tripped(:alarmed, dev, data)
    {:next_state, :idle, data}
  end

  # process alarm event in idle/idle_arm state
  def handle_event(:cast, {_ , dev = %DetectorEv{type: :alarm}}, idle, data)
    when idle in [:idle, :idle_arm] do
    pev = build_partition_ev(:alarm, data.config)
    send data.receiver, {:start, pev}
    data = add_tripped(:alarmed, dev, data)
    {:next_state, :tripped, data}
  end

  # process arm request in idle state
  def handle_event({:call, from}, {:arm, mode, exit_timeout}, :idle, data)
    when mode in [:stay, :immediate, :normal] and is_integer(exit_timeout) do

    # prepare a new arm ev var to be sent later
    partial = mode in [:stay, :immediate]
    arm_ev = %ArmEv{name: data.config.name, partial: partial}

    # check all sensors status
    all_idle = Enum.all?(data.config.sensors, fn(sensor) ->
      :idle == Detector.status({sensor})
    end)

    with true <- all_idle do
      if exit_timeout > 0 do
        if mode in [:stay, :normal] do
          arm_sensors(data, mode)
          send data.receiver, {:start, arm_ev}
          send data.receiver, {:start, %ExitTimerEv{name: data.config.name}}
          # move to exit_wait state and send back :ok
          {:next_state, :exit_wait, data, [
            {:reply, from, :ok},
            {:state_timeout, exit_timeout, :exit_timer_expired}
            ]}
        else
          arm_sensors(data, mode)
          send data.receiver, {:start, arm_ev}
          # move to idle_arm state and send back :ok
          {:next_state, :idle_arm, data, {:reply, from, :ok}}
        end
      else
        arm_sensors(data, mode)
        send data.receiver, {:start, arm_ev}
        # move to idle_arm state and send back :ok
        {:next_state, :idle_arm, data, {:reply, from, :ok}}
      end
    else
      # blah blah keep state and send back {:error, :tripped}
      _ ->
        Logger.error "Not all sensors are idle, cannot arm!"
        {:keep_state_and_data, {:reply, from, {:error, :tripped}}}
    end
  end

  # process disarm request in idle_arm state
  def handle_event({:call, from}, :disarm, :idle_arm, data) do
    Enum.each(data.config.sensors, fn(sensor) ->
      :ok = Detector.disarm({sensor})
    end)
    send data.receiver, {:stop, %ArmEv{name: data.config.name}}
    {:next_state, :idle, data, {:reply, from, :ok}}
  end

  #
  # :exit_wait state callbacks
  #
  # process idle event in exit_wait state
  def handle_event(:cast, {_ , _ = %DetectorEv{type: :idle}}, :exit_wait, _data) do
    :keep_state_and_data
  end

  # process timer expire event in exit_wait state
  def handle_event(:state_timeout, :exit_timer_expired, :exit_wait, data) do
    send data.receiver, {:stop, %ExitTimerEv{name: data.config.name}}
    {:next_state, :idle_arm, data}
  end

  # process alarm event in exit_wait state
  def handle_event(:cast,  {_ , dev = %DetectorEv{type: :alarm}}, :exit_wait, data) do
    send data.receiver, {:stop, %ExitTimerEv{name: data.config.name}}
    send data.receiver, {:start, build_partition_ev(:alarm, data.config)}
    data = add_tripped(:alarmed, dev, data)
    {:next_state, :tripped, data}
  end

  # process tamper event in exit_wait state
  def handle_event(:cast, {_ , dev = %DetectorEv{type: tamper}}, :exit_wait, data)
    when tamper in [:short, :tamper, :fault] do
    send data.receiver, {:stop, %ExitTimerEv{name: data.config.name}}
    send data.receiver, {:start, build_partition_ev(:tamper, data.config)}
    data = add_tripped(:tampered, dev, data)
    {:next_state, :tripped, data}
  end

  # process disarm request in exit_wait state
  def handle_event({:call, from}, :disarm, :exit_wait, data) do
    Enum.each(data.config.sensors, fn(sensor) ->
      :ok = Detector.disarm({sensor})
    end)
    send data.receiver, {:stop, %ExitTimerEv{name: data.config.name}}
    send data.receiver, {:stop, %ArmEv{name: data.config.name}}
    {:next_state, :idle, data, {:reply, from, :ok}}
  end

  #
  # :tripped state callbacks
  #
  # process idle event in tripped state
  def handle_event(:cast, {_ , dev = %DetectorEv{type: :idle}}, :tripped, data) do
    data = if Enum.empty?(data.alarmed) do
      data
    else
      newdata = drop_tripped(:alarmed, dev, data)
      if Enum.empty?(newdata.alarmed) do
        send newdata.receiver, {:stop, build_partition_ev(:alarm, newdata.config)}
      end
      newdata
    end

    data = if Enum.empty?(data.tampered) do
      data
    else
      newdata = drop_tripped(:tampered, dev, data)
      if Enum.empty?(newdata.tampered) do
        send newdata.receiver, {:stop, build_partition_ev(:tamper, newdata.config)}
      end
      newdata
    end

    with true <- Enum.empty?(data.alarmed),
      true <- Enum.empty?(data.tampered)
    do
      {:next_state, :idle_arm, data}
    else
      _ ->
        {:next_state, :tripped, data}
    end
  end

  # process alarm event in tripped state
  def handle_event(:cast, {_ , dev = %DetectorEv{type: :alarm}}, :tripped, data) do
    if Enum.empty?(data.alarmed) do
      send data.receiver, {:start, build_partition_ev(:alarm, data.config)}
    end
    data = add_tripped(:alarmed, dev, data)
    {:next_state, :tripped, data}
  end

  # process tamper event in tripped state
  def handle_event(:cast, {_ , dev = %DetectorEv{type: tamper}}, :tripped, data)
    when tamper in [:short, :tamper, :fault] do
    if Enum.empty?(data.tampered) do
      send data.receiver, {:start, build_partition_ev(:tamper, data.config)}
    end
    data = add_tripped(:tampered, dev, data)
    {:next_state, :tripped, data}
  end

  # process disarm request in tripped state
  def handle_event({:call, from}, :disarm, :tripped, data) do
    Enum.each(data.config.sensors, fn(sensor) ->
      :ok = Detector.disarm({sensor})
    end)

    # empty our tripped lists, send events if applicable
    alarmed = if Enum.empty?(data.alarmed) do
      []
    else
      send data.receiver, {:stop, build_partition_ev(:alarm, data.config)}
      []
    end

    tampered = if Enum.empty?(data.tampered) do
      []
    else
      send data.receiver, {:stop, build_partition_ev(:tamper, data.config)}
      []
    end

    send data.receiver, {:stop, %ArmEv{name: data.config.name}}

    newdata = %{data | alarmed: alarmed, tampered: tampered}
    {:next_state, :idle, newdata, {:reply, from, :ok}}
  end

  #
  # private helper functions
  #

  defp build_partition_ev(type, conf = %PartitionModel{}) when is_atom(type) do
    %PartitionEv{type: type, name: conf.name}
  end

  defp add_tripped(:tampered, ev = %DetectorEv{}, data) do
    newtampered = {ev.address, ev.port}
    %{data | tampered: [newtampered | data.tampered]}
  end

  defp add_tripped(:alarmed, ev = %DetectorEv{}, data) do
    newalarmed = {ev.address, ev.port}
    %{data | alarmed: [newalarmed | data.alarmed]}
  end

  defp drop_tripped(:tampered, ev = %DetectorEv{}, data) do
    newtampered = Enum.reject(data.tampered, fn(item) ->
      item == {ev.address, ev.port}
    end)
    %{data | tampered: newtampered}
  end

  defp drop_tripped(:alarmed, ev = %DetectorEv{}, data) do
    newalarmed = Enum.reject(data.alarmed, fn(item) ->
      item == {ev.address, ev.port}
    end)
    %{data | alarmed: newalarmed}
  end

  defp arm_sensors(data, mode) do
    Enum.each(data.config.sensors, fn(sensor) ->
      case mode do
        :normal ->
          Detector.arm({sensor})
        v when v in [:stay, :immediate] ->
          Detector.arm({sensor, v})
      end
    end)
  end
end
