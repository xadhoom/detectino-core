defmodule DtCore.Test.Sensor.Worker do
  use DtCore.EctoCase

  alias DtCore.Sensor.Worker
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv

  @arm_disarmed "DISARM"
  @arm_armed "ARM"

  @nc_model %SensorModel{name: "NC", address: "1", port: 1,
    balance: "NC", th1: 10, partitions: [], enabled: true}
  @no_model %SensorModel{name: "NO", address: "1", port: 1,
    balance: "NO", th1: 10, partitions: [], enabled: true}
  @eol_model %SensorModel{name: "EOL", address: "1", port: 1,
    balance: "EOL", th1: 10, th2: 20, partitions: [], enabled: true}
  @deol_model %SensorModel{name: "DEOL", address: "1", port: 1,
    balance: "DEOL", th1: 10, th2: 20, th3: 30, partitions: [],
    enabled: true}
  @teol_model %SensorModel{name: "TEOL", address: "1", port: 1,
    balance: "TEOL", th1: 10, th2: 20, th3: 30, th4: 40, partitions: [],
    enabled: true}

  test "no alarm but simple events if partion is not armed" do
    part = %PartitionModel{name: "prot", armed: @arm_disarmed}
    config = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    {:ok, pid} = Worker.start_link({config, part, self})

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:event, %SensorEv{type: :reading, address: "1", port: 1}}
    |> assert_receive(5000)
  end

  test "triggers alarm on immediate sensor" do
    part = %PartitionModel{name: "part1", armed: @arm_armed}
    config = %SensorModel{name: "NC", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    {:ok, pid} = Worker.start_link({config, part, self})

    arm_cmd = {:arm, part.exit_delay}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:event, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
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
    {:ok, pid} = Worker.start_link({config, part, self})

    ev = %Event{address: "1", port: 1, value: 45}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:event, %SensorEv{type: :tamper, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 35}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:event, %SensorEv{type: :fault, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 25}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:event, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:event, %SensorEv{type: :standby, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev, part}, [])
    {:event, %SensorEv{type: :short, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
  end

  test "alarm on entry is delayed by partion time if sensor is a delayed one" do
    part = %PartitionModel{
      name: "part1",
      armed: @arm_armed,
      entry_delay: 1
      }
    config = %SensorModel{
      name: "sense2",
      address: "1",
      port: 1,
      balance: "NC",
      th1: 10,
      entry_delay: true,
      exit_delay: true,
      partitions: [],
      enabled: true
    }
    {:ok, pid} = Worker.start_link({config, part, self})

    arm_cmd = {:arm, part.exit_delay}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])
    
    {:event, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)

    {:event, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
  end

  test "delayed alarm on entry is cancelled if partition is unarmed in time" do
    part = %PartitionModel{
      name: "part1",
      armed: @arm_armed,
      entry_delay: 1
      }
    config = %SensorModel{
      name: "sense1",
      balance: "NC",
      th1: 10,
      entry_delay: true,
      partitions: [],
      address: "1", port: 1,
      enabled: true
    }
    {:ok, pid} = Worker.start_link({config, part, self})
    arm_cmd = {:arm, 0}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:event, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)

    disarm_cmd = {:disarm}
    :ok = GenServer.call(pid, disarm_cmd)

    {:event, %SensorEv{type: :reading, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
  end 

  test "delayed alarm on exit" do
    part = %PartitionModel{
      name: "part1",
      armed: @arm_armed,
      entry_delay: 30,
      exit_delay: 1
      }
    config = %SensorModel{
      name: "sense1",
      balance: "NC",
      th1: 10,
      entry_delay: true,
      exit_delay: true,
      partitions: [],
      address: "1", port: 1,
      enabled: true
    }
    {:ok, pid} = Worker.start_link({config, part, self})

    arm_cmd = {:arm, part.exit_delay}
    :ok = GenServer.call(pid, arm_cmd)

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    {:event, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)

    {:event, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
  end 

end