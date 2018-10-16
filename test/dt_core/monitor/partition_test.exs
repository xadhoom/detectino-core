defmodule DtCore.Test.Monitor.Partition do
  use ExUnit.Case, async: true

  alias DtCore.ArmEv
  alias DtCore.Event
  alias DtCore.ExitTimerEv
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.DetectorEntryEv
  alias DtCore.PartitionEv
  alias DtCore.EventBridge
  alias DtCore.Monitor.Detector
  alias DtCore.Monitor.Partition
  alias DtCore.Monitor.Utils
  alias DtCtx.Monitoring.Sensor, as: SensorModel
  alias DtCtx.Monitoring.Partition, as: PartitionModel
  alias DtCore.Test.TimerHelper

  setup_all do
    {:ok, _} = Registry.start_link(keys: :duplicate, name: DtCore.OutputsRegistry.registry())
    {:ok, _} = EventBridge.start_link()
    :ok
  end

  setup do
    EventBridge.start_listening(fn {_key, payload} ->
      case payload do
        {_, %DetectorEv{}} -> false
        {_, %DetectorExitEv{}} -> false
        {_, %DetectorEntryEv{}} -> false
        _ -> true
      end
    end)

    on_exit(fn ->
      # disconnect from the ev bridge, even if the dead process
      # should remove it automatically
      EventBridge.stop_listening()
    end)

    :ok
  end

  test "on startup a partition subscribes to its sensors" do
    sensor = %SensorModel{
      name: "NC",
      balance: "NC",
      th1: 10,
      partitions: [],
      enabled: true,
      address: "1",
      port: 1
    }

    partition = %PartitionModel{name: "prot", armed: "DISARM", sensors: [sensor]}

    {:ok, sensor_pid} = Detector.start_link({sensor})
    {:ok, p_pid} = Partition.start_link(partition)

    {:links, links} = :erlang.process_info(sensor_pid, :links)
    assert p_pid in links
  end

  test "armed partition from db starts armed" do
    {partition, _} = start_armed_partition("ARM")
    assert :idle_arm == Partition.status({partition})

    {partition, _} = start_armed_partition("ARMSTAY")
    assert :idle_arm == Partition.status({partition})

    {partition, _} = start_armed_partition("ARMSTAYIMMEDIATE")
    assert :idle_arm == Partition.status({partition})
  end

  test "idle sensor event when idle" do
    {partition, p_pid} = start_partition()
    assert :idle == Partition.status({partition})

    send_idle_event(p_pid)
    assert :idle == Partition.status({partition})

    refute_receive _
  end

  test "tamper sensor event when idle" do
    {partition, p_pid} = start_partition()
    assert :idle == Partition.status({partition})

    send_tamper_event(p_pid)
    assert :tripped == Partition.status({partition})
    assert_recv_partev(:start, :tamper, partition.name)

    refute_receive _
  end

  test "realtime sensor event when idle" do
    {partition, p_pid} = start_partition()
    assert :idle == Partition.status({partition})

    send_realtime_event(p_pid)
    assert :idle == Partition.status({partition})

    refute_receive _
  end

  test "alarm sensor event when idle" do
    {partition, p_pid} = start_partition()
    name = partition.name
    assert :idle == Partition.status({partition})

    send_alarm_event(p_pid)
    assert :tripped == Partition.status({partition})
    assert_recv_partev(:start, :alarm, name)

    refute_receive _
  end

  test "total arm an idle partition" do
    {:ok, sensor, s_pid} = setup_teol_sensor()
    {partition, _p_pid} = start_partition([sensor])

    assert :idle == Partition.status({partition})
    assert :idle == Detector.status(s_pid)

    :ok = Partition.arm(partition, "foo")

    assert :idle_arm == Partition.status({partition})
    assert :idle_arm == Detector.status(s_pid)
    assert_recv_armev("foo", :start, false, partition.name)

    refute_receive _
  end

  test "total arm an idle partition with some tripped sensors" do
    {:ok, sensor, s_pid} = setup_teol_sensor()
    {partition, _p_pid} = start_partition([sensor])
    assert :idle == Partition.status({partition})

    # send an alarm event to sensor
    ev = %Event{address: sensor.address, port: sensor.port, value: 25}
    :ok = Process.send(s_pid, {:event, ev}, [])
    assert_eq_wait(:realtime, Detector.status({sensor}))

    assert {:error, :tripped} == Partition.arm(partition, "foo")

    assert :realtime == Detector.status({sensor})
    assert :idle == Partition.status({partition})

    refute_receive _
  end

  test "total arm a delayed idle partition" do
    {:ok, sensor, _s_pid} = setup_teol_sensor({0, 30})
    {partition, _p_pid} = start_partition(0, 30, [sensor])
    assert :idle == Partition.status({partition})

    :ok = Partition.arm(partition, "foo")
    assert :exit_wait == Partition.status({partition})
    assert :exit_wait == Detector.status({sensor})

    assert_recv_armev("foo", :start, false, partition.name)
    assert_recv_exitev(:start, partition.name)

    refute_receive _
  end

  test "total arm a delayed idle partition (low delay)" do
    {:ok, sensor, _s_pid} = setup_teol_sensor({0, 1})
    {partition, _p_pid} = start_partition(0, 1, [sensor])
    assert :idle == Partition.status({partition})

    :ok = Partition.arm(partition, "foo")
    assert :exit_wait == Partition.status({partition})
    assert :exit_wait == Detector.status({sensor})

    assert_recv_armev("foo", :start, false, partition.name)
    assert_recv_exitev(:start, partition.name)
    assert_recv_exitev(:stop, partition.name)
    assert :idle_arm == Partition.status({partition})
    assert :idle_arm == Detector.status({sensor})

    refute_receive _
  end

  test "partial arm an idle partition" do
    {:ok, sensor, _s_pid} = setup_internal_teol_sensor({0, 30})
    {partition, _p_pid} = start_partition(0, 30, [sensor])
    assert :idle == Partition.status({partition})

    :ok = Partition.arm(partition, "foo", :stay)
    assert :exit_wait == Partition.status({partition})
    assert :idle == Detector.status({sensor})

    assert_recv_armev("foo", :start, true, partition.name)
    assert_recv_exitev(:start, partition.name)

    refute_receive _
  end

  test "partial, immediate arm an idle partition" do
    {:ok, sensor, _s_pid} = setup_internal_teol_sensor({0, 30})
    {partition, _p_pid} = start_partition(0, 30, [sensor])
    assert :idle == Partition.status({partition})

    :ok = Partition.arm(partition, "foo", :immediate)
    assert :idle_arm == Partition.status({partition})
    assert :idle == Detector.status({sensor})

    assert_recv_armev("foo", :start, true, partition.name)
    assert :idle_arm == Partition.status({partition})
    assert :idle == Detector.status({sensor})

    refute_receive _
  end

  test "disarm partition" do
    {:ok, sensor, s_pid} = setup_teol_sensor()
    {partition, _p_pid} = start_partition([sensor])

    assert :idle == Partition.status({partition})
    assert :idle == Detector.status(s_pid)

    :ok = Partition.arm(partition, "foo")
    assert :idle_arm == Partition.status({partition})
    assert :idle_arm == Detector.status(s_pid)
    assert_recv_armev("foo", :start, false, partition.name)

    # disarm
    :ok = Partition.disarm(partition, "baz")
    assert :idle == Partition.status({partition})
    assert :idle == Detector.status(s_pid)
    assert_recv_armev("baz", :stop, false, partition.name)

    refute_receive _
  end

  test "alarm event during exit wait state" do
    {:ok, sensor, s_pid} = setup_teol_sensor()
    {partition, _p_pid} = start_partition(0, 30, [sensor])

    :ok = Partition.arm(partition, "foo")
    assert :exit_wait == Partition.status({partition})
    assert_recv_armev("foo", :start, false, partition.name)
    assert_recv_exitev(:start, partition.name)

    # send an alarm event
    ev = %Event{address: sensor.address, port: sensor.port, value: 25}
    :ok = Process.send(s_pid, {:event, ev}, [])
    assert_eq_wait(:alarmed_arm, Detector.status({sensor}))
    assert_eq_wait(:tripped, Partition.status({partition}))

    assert_recv_exitev(:stop, partition.name)
    assert_recv_partev(:start, :alarm, partition.name)

    refute_receive _
  end

  test "tamper event during exit wait state" do
    {:ok, sensor, s_pid} = setup_teol_sensor()
    {partition, _p_pid} = start_partition(0, 30, [sensor])

    :ok = Partition.arm(partition, "foo")
    assert :exit_wait == Partition.status({partition})
    assert_recv_armev("foo", :start, false, partition.name)
    assert_recv_exitev(:start, partition.name)

    # send a tamper event
    ev = %Event{address: sensor.address, port: sensor.port, value: 5}
    :ok = Process.send(s_pid, {:event, ev}, [])
    assert_eq_wait(:tampered_arm, Detector.status({sensor}))
    assert_eq_wait(:tripped, Partition.status({partition}))

    assert_recv_exitev(:stop, partition.name)
    assert_recv_partev(:start, :tamper, partition.name)

    refute_receive _
  end

  test "disarm request during exit wait state" do
    {:ok, sensor, _s_pid} = setup_teol_sensor({0, 30})
    {partition, _p_pid} = start_partition(0, 30, [sensor])

    :ok = Partition.arm(partition, "foo")
    assert :exit_wait == Detector.status({sensor})
    assert :exit_wait == Partition.status({partition})
    assert_recv_armev("foo", :start, false, partition.name)
    assert_recv_exitev(:start, partition.name)

    # disarm the partition
    :ok = Partition.disarm(partition, "bar")
    # check
    assert :idle == Partition.status({partition})
    assert :idle == Detector.status({sensor})
    assert_recv_exitev(:stop, partition.name)
    assert_recv_armev("bar", :stop, false, partition.name)

    refute_receive _
  end

  test "entry event during idle arm state" do
    {:ok, sensor, s_pid} = setup_teol_sensor({1, 0})
    {partition, _p_pid} = start_partition(1, 0, [sensor])

    assert :idle == Partition.status({partition})
    assert :idle == Detector.status(s_pid)

    :ok = Partition.arm(partition, "foo")
    assert :idle_arm == Partition.status({partition})
    assert :idle_arm == Detector.status(s_pid)
    assert_recv_armev("foo", :start, false, partition.name)

    # send an alarm event, will cause an entry delay
    ev = %Event{address: sensor.address, port: sensor.port, value: 25}
    :ok = Process.send(s_pid, {:event, ev}, [])
    assert_eq_wait(:entry_wait, Detector.status({sensor}))
    assert_eq_wait(:idle_arm, Partition.status({partition}))

    assert_recv_partev(:start, :alarm, partition.name)
    assert :alarmed_arm == Detector.status({sensor})
    assert :tripped == Partition.status({partition})

    refute_receive _
  end

  test "idle event on single alarm tripped partition" do
    # setup a tripped partition with single sensor
    # and do preliminary assertions / messages checks
    {partition, sensor, _p_pid, s_pid} = start_tripped_partion(:alarm)

    # premilinary checks
    assert_eq_wait(:alarmed_arm, Detector.status({sensor}))
    assert_eq_wait(:tripped, Partition.status({partition}))

    # check events
    assert_recv_armev("bob", :start, false, partition.name)
    assert_recv_partev(:start, :alarm, partition.name)

    # now send an idle event
    ev = %Event{address: sensor.address, port: sensor.port, value: 15}
    :ok = Process.send(s_pid, {:event, ev}, [])

    # check that system goes back to idle (armed)
    assert_eq_wait(:idle_arm, Detector.status({sensor}))
    assert_eq_wait(:idle_arm, Partition.status({partition}))
    assert_recv_partev(:stop, :alarm, partition.name)

    refute_receive _
  end

  test "idle event on single tamper tripped partition" do
    # setup a tripped partition with single sensor
    # and do preliminary assertions / messages checks
    {partition, sensor, _p_pid, s_pid} = start_tripped_partion(:tamper)

    # premilinary checks
    assert_eq_wait(:tampered_arm, Detector.status({sensor}))
    assert_eq_wait(:tripped, Partition.status({partition}))

    # check events
    assert_recv_armev("bob", :start, false, partition.name)
    assert_recv_partev(:start, :tamper, partition.name)

    # now send an idle event
    ev = %Event{address: sensor.address, port: sensor.port, value: 15}
    :ok = Process.send(s_pid, {:event, ev}, [])

    # check that system goes back to idle (armed)
    assert_eq_wait(:idle_arm, Detector.status({sensor}))
    assert_eq_wait(:idle_arm, Partition.status({partition}))

    assert_recv_partev(:stop, :tamper, partition.name)

    refute_receive _
  end

  test "idle event on multiple alarm tripped partition" do
    # setup a multiple tripped partition with single sensor
    # and do preliminary assertions / messages checks
    {partition, sensors, _p_pid, s_pids} = start_m_tripped_partion(:alarm)

    # check events
    assert_recv_armev("alice", :start, false, partition.name)
    assert_recv_partev(:start, :alarm, partition.name)

    # should be tripped
    assert :tripped == Partition.status({partition})

    # now send an idle event to only one sensor
    sensor = Enum.at(sensors, 0)
    ev = %Event{address: sensor.address, port: sensor.port, value: 15}
    :ok = Process.send(Enum.at(s_pids, 0), {:event, ev}, [])

    # check that system stays in tripped state
    assert_eq_wait(:idle_arm, Detector.status({Enum.at(sensors, 0)}))
    assert_eq_wait(:alarmed_arm, Detector.status({Enum.at(sensors, 1)}))
    assert :tripped == Partition.status({partition})

    # idle also second sensor
    sensor = Enum.at(sensors, 1)
    ev = %Event{address: sensor.address, port: sensor.port, value: 15}
    :ok = Process.send(Enum.at(s_pids, 1), {:event, ev}, [])

    # check that system stays in tripped state
    assert_eq_wait(:idle_arm, Detector.status({Enum.at(sensors, 0)}))
    assert_eq_wait(:idle_arm, Detector.status({Enum.at(sensors, 1)}))
    assert_eq_wait(:idle_arm, Partition.status({partition}))

    assert_recv_partev(:stop, :alarm, partition.name)

    refute_receive _
  end

  test "idle event on multiple tamper tripped partition" do
    # setup a multiple tripped partition
    # and do preliminary assertions / messages checks
    {partition, sensors, _p_pid, s_pids} = start_m_tripped_partion(:tamper)

    # check events
    assert_recv_armev("alice", :start, false, partition.name)
    assert_recv_partev(:start, :tamper, partition.name)

    # should be tripped
    assert :tripped == Partition.status({partition})

    # now send an idle event to only one sensor
    sensor = Enum.at(sensors, 0)
    ev = %Event{address: sensor.address, port: sensor.port, value: 15}
    :ok = Process.send(Enum.at(s_pids, 0), {:event, ev}, [])

    # check that system stays in tripped state
    assert_eq_wait(:idle_arm, Detector.status({Enum.at(sensors, 0)}))
    assert_eq_wait(:tampered_arm, Detector.status({Enum.at(sensors, 1)}))
    assert_eq_wait(:tripped, Partition.status({partition}))

    # idle also second sensor
    sensor = Enum.at(sensors, 1)
    ev = %Event{address: sensor.address, port: sensor.port, value: 15}
    :ok = Process.send(Enum.at(s_pids, 1), {:event, ev}, [])

    # check that system goes back to idle
    assert_eq_wait(:idle_arm, Detector.status({Enum.at(sensors, 0)}))
    assert_eq_wait(:idle_arm, Detector.status({Enum.at(sensors, 1)}))
    assert_eq_wait(:idle_arm, Partition.status({partition}))

    assert_recv_partev(:stop, :tamper, partition.name)

    refute_receive _
  end

  test "idle event on multiple mixed tripped partition" do
    # setup a mixed tripped partition
    {partition, sensors, _p_pid, s_pids} = start_mixed_tripped_partion()

    # check events
    assert_recv_armev("cat", :start, false, partition.name)
    assert_recv_partev(:start, :alarm, partition.name)
    assert_recv_partev(:start, :tamper, partition.name)

    # should be tripped
    assert :tripped == Partition.status({partition})

    # now send an idle event to only one sensor
    sensor = Enum.at(sensors, 0)
    ev = %Event{address: sensor.address, port: sensor.port, value: 15}
    :ok = Process.send(Enum.at(s_pids, 0), {:event, ev}, [])

    # check that system stays in tripped state
    assert_recv_partev(:stop, :tamper, partition.name)
    assert :idle_arm == Detector.status({Enum.at(sensors, 0)})
    assert :alarmed_arm == Detector.status({Enum.at(sensors, 1)})
    assert :tripped == Partition.status({partition})

    # idle also second sensor
    sensor = Enum.at(sensors, 1)
    ev = %Event{address: sensor.address, port: sensor.port, value: 15}
    :ok = Process.send(Enum.at(s_pids, 1), {:event, ev}, [])

    # check that system goes back to idle
    assert_recv_partev(:stop, :alarm, partition.name)
    assert :idle_arm == Detector.status({Enum.at(sensors, 0)})
    assert :idle_arm == Detector.status({Enum.at(sensors, 1)})
    assert :idle_arm == Partition.status({partition})

    refute_receive _
  end

  test "disarm a tripped partition" do
    {partition, sensor, _p_pid, _s_pid} = start_tripped_partion(:alarm)

    # premilinary checks
    assert_eq_wait(:alarmed_arm, Detector.status({sensor}))
    assert_eq_wait(:tripped, Partition.status({partition}))

    # check events
    assert_recv_armev("bob", :start, false, partition.name)
    assert_recv_partev(:start, :alarm, partition.name)

    :ok = Partition.disarm(partition, "alice")
    assert_recv_partev(:stop, :alarm, partition.name)
    assert_recv_armev("alice", :stop, false, partition.name)
    assert :idle == Partition.status({partition})

    refute_receive _
  end

  defp assert_recv_partev(operation, type, name)
       when operation in [:start, :stop] and is_atom(type) do
    {:bridge_ev, _, {^operation, %PartitionEv{type: ^type, name: ^name}}}
    |> assert_receive(5000)
  end

  defp assert_eq_wait(a, b) do
    # this assertion depends on messages between processes,
    # so give them time to land :)
    TimerHelper.wait_until(5000, fn ->
      assert a == b
    end)
  end

  defp assert_recv_armev(initiator, operation, partial, name)
       when operation in [:start, :stop] and partial in [true, false, nil] do
    {:bridge_ev, _,
     {^operation, %ArmEv{partial: ^partial, name: ^name, id: _, initiator: ^initiator}}}
    |> assert_receive(5000)
  end

  defp assert_recv_exitev(operation, name) when operation in [:start, :stop] do
    {:bridge_ev, _, {^operation, %ExitTimerEv{name: ^name}}}
    |> assert_receive(5000)
  end

  defp start_partition(sensors \\ []) when is_list(sensors) do
    partition = %PartitionModel{name: UUID.uuid4(), armed: "DISARM", sensors: sensors}
    {:ok, p_pid} = Partition.start_link(partition)
    {partition, p_pid}
  end

  defp start_armed_partition(mode, sensors \\ [])
       when is_list(sensors) and mode in ["ARM", "ARMSTAY", "ARMSTAYIMMEDIATE"] do
    partition = %PartitionModel{name: UUID.uuid4(), armed: mode, sensors: sensors}
    {:ok, p_pid} = Partition.start_link(partition)
    {partition, p_pid}
  end

  defp start_partition(entry_delay, exit_delay, sensors)
       when is_integer(entry_delay) and is_integer(exit_delay) do
    partition = %PartitionModel{
      name: UUID.uuid4(),
      armed: "DISARM",
      entry_delay: entry_delay,
      exit_delay: exit_delay,
      sensors: sensors
    }

    {:ok, p_pid} = Partition.start_link(partition)
    {partition, p_pid}
  end

  defp start_tripped_partion(type) do
    {:ok, sensor, s_pid} = setup_teol_sensor()
    {partition, p_pid} = start_partition([sensor])

    :ok = Partition.arm(partition, "bob")

    assert :idle_arm == Partition.status({partition})
    assert :idle_arm == Detector.status({sensor})

    # send a tripping event to sensor
    value =
      case type do
        :alarm -> 25
        :tamper -> 5
        _ -> 25
      end

    ev = %Event{address: sensor.address, port: sensor.port, value: value}
    :ok = Process.send(s_pid, {:event, ev}, [])

    {partition, sensor, p_pid, s_pid}
  end

  defp start_m_tripped_partion(type) do
    sensor1 = %SensorModel{
      name: UUID.uuid4(),
      balance: "TEOL",
      th1: 10,
      th2: 20,
      th3: 30,
      th4: 40,
      entry_delay: false,
      exit_delay: false,
      partitions: [],
      address: "3",
      port: 3,
      enabled: true
    }

    sensor2 = %SensorModel{sensor1 | name: UUID.uuid4(), port: 4}
    {:ok, s_pid1} = Detector.start_link({sensor1})
    {:ok, s_pid2} = Detector.start_link({sensor2})

    {partition, p_pid} = start_partition([sensor1, sensor2])

    :ok = Partition.arm(partition, "alice")

    assert :idle_arm == Partition.status({partition})
    assert :idle_arm == Detector.status({sensor1})
    assert :idle_arm == Detector.status({sensor2})

    # send a tripping event to sensors
    value =
      case type do
        :alarm -> 25
        :tamper -> 5
        _ -> 25
      end

    ev1 = %Event{address: sensor1.address, port: sensor1.port, value: value}
    ev2 = %Event{address: sensor2.address, port: sensor2.port, value: value}
    :ok = Process.send(s_pid1, {:event, ev1}, [])
    :ok = Process.send(s_pid2, {:event, ev2}, [])

    {partition, [sensor1, sensor2], p_pid, [s_pid1, s_pid2]}
  end

  defp start_mixed_tripped_partion do
    sensor1 = %SensorModel{
      name: UUID.uuid4(),
      balance: "TEOL",
      th1: 10,
      th2: 20,
      th3: 30,
      th4: 40,
      entry_delay: false,
      exit_delay: false,
      partitions: [],
      address: "3",
      port: 3,
      enabled: true
    }

    sensor2 = %SensorModel{sensor1 | name: UUID.uuid4(), port: 4}
    {:ok, s_pid1} = Detector.start_link({sensor1})
    {:ok, s_pid2} = Detector.start_link({sensor2})

    {partition, p_pid} = start_partition([sensor1, sensor2])

    :ok = Partition.arm(partition, "cat")

    assert :idle_arm == Partition.status({partition})
    assert :idle_arm == Detector.status({sensor1})
    assert :idle_arm == Detector.status({sensor2})

    # send a tripping event to sensors (tamper to 1st, alarm to 2nd)
    ev1 = %Event{address: sensor1.address, port: sensor1.port, value: 5}
    ev2 = %Event{address: sensor2.address, port: sensor2.port, value: 25}
    :ok = Process.send(s_pid1, {:event, ev1}, [])
    :ok = Process.send(s_pid2, {:event, ev2}, [])

    {partition, [sensor1, sensor2], p_pid, [s_pid1, s_pid2]}
  end

  defp send_idle_event(pid, op \\ :start) when op in [:start, :stop] do
    ev = {op, %DetectorEv{type: :idle, address: "1", port: 1, id: Utils.random_id()}}
    send(pid, ev)
  end

  defp send_tamper_event(pid, op \\ :start) when op in [:start, :stop] do
    ev = {op, %DetectorEv{type: :short, address: "1", port: 1, id: Utils.random_id()}}
    send(pid, ev)
  end

  defp send_realtime_event(pid, op \\ :start) when op in [:start, :stop] do
    ev = {op, %DetectorEv{type: :realtime, address: "1", port: 1, id: Utils.random_id()}}
    send(pid, ev)
  end

  defp send_alarm_event(pid, op \\ :start) when op in [:start, :stop] do
    ev = {op, %DetectorEv{type: :alarm, address: "1", port: 1, id: Utils.random_id()}}
    send(pid, ev)
  end

  defp setup_teol_sensor({entry_delay, exit_delay} \\ {0, 0}) do
    sensor = %SensorModel{
      name: UUID.uuid4(),
      balance: "TEOL",
      th1: 10,
      th2: 20,
      th3: 30,
      th4: 40,
      entry_delay: is_integer(entry_delay) and entry_delay > 0,
      exit_delay: is_integer(exit_delay) and exit_delay > 0,
      partitions: [],
      address: "3",
      port: 3,
      enabled: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    {:ok, sensor, pid}
  end

  defp setup_internal_teol_sensor({entry_delay, exit_delay}) do
    sensor = %SensorModel{
      name: UUID.uuid4(),
      balance: "TEOL",
      th1: 10,
      th2: 20,
      th3: 30,
      th4: 40,
      entry_delay: is_integer(entry_delay) and entry_delay > 0,
      exit_delay: is_integer(exit_delay) and exit_delay > 0,
      partitions: [],
      address: "3",
      port: 3,
      enabled: true,
      internal: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    {:ok, sensor, pid}
  end
end
