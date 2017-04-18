defmodule DtCore.Test.Sensor.Worker do
  use ExUnit.Case, async: false

  alias DtCore.Sensor.Worker
  alias DtCore.Sensor.Utils
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel
  alias DtCore.Event, as: Event
  alias DtCore.SensorEv
  alias DtCore.Test.TimerHelper

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
     {:ok, part, config, pid} = setup_delayed_nc(3, false)

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
    # we're mocking here to avoid calling exit timer
    # since it may cause duplicate events in our test
    :ok = setup_etimer_meck()

    {:ok, part, config, pid} = setup_delayed_nc(60, false)

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

    refute_received _
    :ok = clean_etimer_meck()
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

  test "delayed alarm on entry is restarted on a new alarm event" do
    :ok = setup_etimer_meck()

    # setup sensor
    {:ok, part, config, pid} = setup_delayed_nc(60, false)
    {:ok, server_name} = Utils.sensor_server_name(config, part)

    # arm sensor (immediate arming, since we're testing entry)
    arm_cmd = {:arm, 0}
    :ok = GenServer.call(pid, arm_cmd)

    # sends a reading that triggers an alarm
    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    # entry timer should kick in (on busy system may not be immediate)
    TimerHelper.wait_until fn() ->
      assert :meck.called(
        Etimer, :start_timer,
        [:_, :entry_timer, part.entry_delay * 1000,
          {Worker, :expire_timer, [{:entry_timer, server_name}]}
        ]
      )
    end
    # and we must forcefully trigger it, since is mocked
    Worker.expire_timer({:entry_timer, server_name})
    # and flush the events
    send pid, {:flush, :entry}
    # now check
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    # now put the sensor back in idle status
    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev, part}, [])

    # check that the alarm is stopped
    {:stop, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)

    :ok = clean_etimer_meck()
    :ok = setup_etimer_meck()

    # send another alarm reading
    IO.inspect :sending_another_alarm
    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    # entry timer should start again
    assert :meck.called(
      Etimer, :start_timer,
      [:_, :entry_timer, part.entry_delay * 1000,
        {Worker, :expire_timer, [{:entry_timer, server_name}]}
      ]
    )

    :ok = clean_etimer_meck()
  end

  test "delayed alarm on exit is not restarted on a new alarm event" do
    # but instead should be immediate
    :ok = setup_etimer_meck()

    # setup sensor
    {:ok, part, config, pid} = setup_delayed_nc(false, 60)
    {:ok, server_name} = Utils.sensor_server_name(config, part)

    # arm sensor
    arm_cmd = {:arm, part.exit_delay}
    :ok = GenServer.call(pid, arm_cmd)

    # sends a reading that triggers an alarm
    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    # check that a delayed event is sent
    {:stop, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)

    # entry timer should kick in (on busy system may not be immediate)
    TimerHelper.wait_until fn() ->
      assert :meck.called(
        Etimer, :start_timer,
        [:_, :exit_timer, part.exit_delay * 1000,
          {Worker, :expire_timer, [{:exit_timer, server_name}]}
        ]
      )
    end

    # and we must forcefully trigger it, since is mocked
    Worker.expire_timer({:exit_timer, server_name})
    # and flush the events
    send pid, {:flush, :exit}
    # now check
    {:stop, %SensorEv{type: :alarm, address: "1", port: 1, delayed: true}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    # now put the sensor back in idle status
    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev, part}, [])

    # check that the alarm is stopped
    {:stop, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)

    :ok = clean_etimer_meck()
    :ok = setup_etimer_meck()

    # send another alarm reading
    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev, part}, [])

    # entry timer should *not* start again
    refute :meck.called(
      Etimer, :start_timer,
      [:_, :exit_timer, part.exit_delay * 1000,
        {Worker, :expire_timer, [{:exit_timer, server_name}]}
      ]
    )
    {:stop, %SensorEv{type: :standby, address: "1", port: 1}}
    |> assert_receive(5000)
    {:start, %SensorEv{type: :alarm, address: "1", port: 1, delayed: false}}
    |> assert_receive(5000)

    refute_received _
    :ok = clean_etimer_meck()
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

  defp setup_etimer_meck do
    :meck.new(Etimer, [:passthrough])
    :meck.expect(Etimer, :start_timer,
      fn(_ ,_ ,_ ,_ ) ->
        :ok
      end)
    :ok
  end

  defp clean_etimer_meck do
    :meck.unload(Etimer)
    :ok
  end

end
