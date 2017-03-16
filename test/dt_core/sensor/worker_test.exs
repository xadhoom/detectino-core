defmodule DtCore.Test.Sensor.Worker do
  use ExUnit.Case, async: false

  alias DtCore.Sensor.Worker
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv

  @arm_disarmed "DISARM"
  @arm_armed "ARM"

  test "no alarm but simple events if NC partion is not armed" do
    {:ok, part, config, pid} = setup_nc()

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    assert :standby == Worker.alarm_status({config, part})

    {:start, %SensorEv{type: :reading, address: "1", port: 1}}
    |> assert_receive(5000)

    assert :standby == Worker.alarm_status({config, part})
  end

  test "disarm an already disarmed NC sensor" do
    {:ok, part, config, pid} = setup_nc()

    disarm_cmd = {:disarm}
    :ok = GenServer.call(pid, disarm_cmd)

    assert :standby == Worker.alarm_status({config, part})
  end

  test "triggers alarm on immediate NC sensor" do
    {:ok, part, config, pid} = setup_nc()

    arm_cmd = {:arm, part.exit_delay}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    assert :alarm == Worker.alarm_status({config, part})
  end

  test "triggers alarms when partition is not armed and sensor is a 24h" do
    part = %PartitionModel{name: "part1", armed: @arm_disarmed}
    config = %SensorModel{
      name: "sense1",
      full24h: true,
      address: "1", port: 1,
      balance: "TEOL", th1: 10, th2: 20, th3: 30, th4: 40,
      partitions: [],
      enabled: true
    }
    {:ok, pid} = Worker.start_link({config, part, self()})

    ev = %Event{address: "1", port: 1, value: 45}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:stop, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :tamper, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    assert :tamper == Worker.alarm_status({config, part})

    # when event changes a stop of previous event is expected
    ev = %Event{address: "1", port: 1, value: 35}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:stop, %SensorEv{type: :tamper, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :fault, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    assert :fault == Worker.alarm_status({config, part})

    ev = %Event{address: "1", port: 1, value: 25}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:stop, %SensorEv{type: :fault, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    assert :alarm == Worker.alarm_status({config, part})

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:stop, %SensorEv{type: :alarm, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :standby, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    assert :standby == Worker.alarm_status({config, part})

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:stop, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :short, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    assert :tamper == Worker.alarm_status({config, part})
  end

  test "alarm on entry is delayed by partion time if sensor is a delayed one" do
     {:ok, part, config, pid} = setup_delayed_nc(1, false)

    arm_cmd = {:arm, part.exit_delay}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:stop, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)
    assert :alarm == Worker.alarm_status({config, part})

    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    assert :alarm == Worker.alarm_status({config, part})
  end

  test "delayed alarm on entry is cancelled if partition is unarmed in time" do
    {:ok, part, config, pid} = setup_delayed_nc(false, 60)

    arm_cmd = {:arm, 0}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:stop, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)
    assert :alarm == Worker.alarm_status({config, part})

    disarm_cmd = {:disarm}
    :ok = GenServer.call(pid, disarm_cmd)

    {:stop, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :reading, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    assert :standby == Worker.alarm_status({config, part})
  end

  test "delayed alarm on exit is cancelled if partition is unarmed in time" do
    {:ok, part, config, pid} = setup_delayed_nc(false, 60)

    arm_cmd = {:arm, 0}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:stop, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)
    assert :alarm == Worker.alarm_status({config, part})

    disarm_cmd = {:disarm}
    :ok = GenServer.call(pid, disarm_cmd)

    {:stop, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)

    {:start, %SensorEv{type: :reading, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    assert :standby == Worker.alarm_status({config, part})
  end

  test "delayed alarm on exit" do
    {:ok, part, config, pid} = setup_delayed_nc(30, 1)

    arm_cmd = {:arm, part.exit_delay}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:stop, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)
    assert :alarm == Worker.alarm_status({config, part})

    {:stop, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    assert :alarm == Worker.alarm_status({config, part})
  end

  defp setup_nc do
    partition = %PartitionModel{name: "NCPART", armed: @arm_disarmed}
    sensor = %SensorModel{name: "NCSENSOR", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    {:ok, pid} = Worker.start_link({sensor, partition, self()})
    {:ok, partition, sensor, pid}
  end

  defp setup_delayed_nc(entry_delay, exit_delay) do
    partition = %PartitionModel{
      name: "PART_DELAYED",
      armed: @arm_armed,
      entry_delay: entry_delay,
      exit_delay: exit_delay
      }
    sensor = %SensorModel{
      name: "NC_DELAYED",
      balance: "NC",
      th1: 10,
      entry_delay: is_integer(entry_delay),
      exit_delay: is_integer(exit_delay),
      partitions: [],
      address: "1", port: 1,
      enabled: true
    }
    {:ok, pid} = Worker.start_link({sensor, partition, self()})
    {:ok, partition, sensor, pid}
  end

end
