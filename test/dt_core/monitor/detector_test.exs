defmodule DtCore.Test.Monitor.Detector do
  @moduledoc false
  use ExUnit.Case

  alias DtCore.DetectorEntryEv
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.Event
  alias DtCore.Monitor.Detector

  alias DtCtx.Monitoring.Sensor, as: SensorModel

  test "idle events does not trigger any event if not armed" do
    {:ok, config, pid} = setup_nc()

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])

    assert :idle == Detector.status({config})

    refute_receive _
  end

  test "no alarm but realtime event if NC sensor is not armed" do
    {:ok, config, pid} = setup_nc()

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    assert :realtime == Detector.status({config})

    {:start, %DetectorEv{type: :realtime, address: "1", port: 1}}
    |> assert_receive(5000)
  end

  test "alarm event if 24H NC sensor is not armed" do
    {:ok, config, pid} = setup_24h_nc()

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    assert :alarmed == Detector.status({config})

    {:start, %DetectorEv{type: :alarm, address: "1", port: 1}}
    |> assert_receive(5000)
  end

  test "tamper event on not armed sensor" do
    {:ok, config, pid} = setup_eol()

    ev = %Event{address: "2", port: 2, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])

    assert :tampered == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "2", port: 2}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :short, address: "2", port: 2}}
    |> assert_receive(5000)
  end

  test "all events on not armed teol sensor" do
    {:ok, config, pid} = setup_teol()
    assert :idle == Detector.status({config})

    ev = %Event{address: "3", port: 3, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :short, address: "3", port: 3, id: short_ev_id}}
    |> assert_receive(5000)

    ev = %Event{address: "3", port: 3, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :idle == Detector.status({config})

    {:stop, %DetectorEv{type: :short, address: "3", port: 3, id: ^short_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :idle, address: "3", port: 3, id: idle_ev_id}}
    |> assert_receive(5000)

    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :realtime == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3, id: ^idle_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :realtime, address: "3", port: 3, id: rt_ev_id}}
    |> assert_receive(5000)

    ev = %Event{address: "3", port: 3, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})

    {:stop, %DetectorEv{type: :realtime, address: "3", port: 3, id: ^rt_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :fault, address: "3", port: 3, id: fault_ev_id}}
    |> assert_receive(5000)

    ev = %Event{address: "3", port: 3, value: 45}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})

    {:stop, %DetectorEv{type: :fault, address: "3", port: 3, id: ^fault_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "arm a not delayed sensor" do
    {:ok, config, _pid} = setup_eol()

    Detector.arm({config})

    {:start, %DetectorEv{type: :idle, address: "2", port: 2}}
    |> assert_receive(5000)

    assert :idle_arm == Detector.status({config})
  end

  test "partial arming an internal sensor does nothing" do
    {:ok, config, _pid} = setup_internal_eol(0, 0)

    Detector.arm({config, :stay})

    assert :idle == Detector.status({config})

    refute_receive _
  end

  test "partial, immediate arming an internal sensor does nothing" do
    {:ok, config, _pid} = setup_internal_eol(0, 0)

    Detector.arm({config, :immediate})

    assert :idle == Detector.status({config})

    refute_receive _
  end

  test "arm an exit delayed sensor" do
    {:ok, config, _pid} = setup_eol(0, 30)

    Detector.arm({config})

    {:stop, %DetectorEv{type: :idle, address: "2", port: 2}}
    |> assert_receive(5000)

    {:start, %DetectorExitEv{address: "2", port: 2}}
    |> assert_receive(5000)

    assert :exit_wait == Detector.status({config})
  end

  test "arm an exit delayed sensor in immediate mode" do
    {:ok, config, _pid} = setup_eol(0, 30)

    Detector.arm({config, :immediate})

    {:start, %DetectorEv{type: :idle, address: "2", port: 2}}
    |> assert_receive(5000)

    assert :idle_arm == Detector.status({config})

    refute_receive _
  end

  test "arm a tampered sensor" do
    {:ok, config, pid} = setup_deol()

    ev = %Event{address: "4", port: 4, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})

    {:error, :tripped} = Detector.arm({config})
  end

  test "alarm event on a not armed tampered sensor" do
    {:ok, config, pid} = setup_deol()

    # put in tamper state
    ev = %Event{address: "4", port: 4, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})

    # check
    {:stop, %DetectorEv{type: :idle, address: "4", port: 4}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :tamper, address: "4", port: 4, id: tamp_ev_id}}
    |> assert_receive(5000)

    ev = %Event{address: "4", port: 4, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :realtime == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "4", port: 4, id: ^tamp_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :realtime, address: "4", port: 4}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "alarm event on a not armed tampered 24h sensor" do
    {:ok, config, pid} = setup_24h_deol()

    # put in tamper state
    ev = %Event{address: "4", port: 4, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})

    # check
    {:stop, %DetectorEv{type: :idle, address: "4", port: 4}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :tamper, address: "4", port: 4, id: tamp_ev_id}}
    |> assert_receive(5000)

    ev = %Event{address: "4", port: 4, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :alarmed == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "4", port: 4, id: ^tamp_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :alarm, address: "4", port: 4}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "idle event on a sensor in realtime state" do
    {:ok, config, pid} = setup_deol_realtime()

    # put in idle state
    ev = %Event{address: "4", port: 4, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :idle == Detector.status({config})

    {:stop, %DetectorEv{type: :realtime, address: "4", port: 4}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :idle, address: "4", port: 4}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "tamper event on a sensor in realtime state" do
    {:ok, config, pid} = setup_deol_realtime()

    # send tamper event
    ev = %Event{address: "4", port: 4, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})

    {:stop, %DetectorEv{type: :realtime, address: "4", port: 4}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :short, address: "4", port: 4}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "alarm event on a sensor in realtime state" do
    {:ok, config, pid} = setup_deol_realtime()

    # send alarm event
    ev = %Event{address: "4", port: 4, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :realtime == Detector.status({config})

    refute_receive _
  end

  test "arm a sensor in realtime state" do
    {:ok, config, _pid} = setup_deol_realtime()
    {:error, :tripped} = Detector.arm({config})
    refute_receive _
  end

  test "disarm sensor while is in realtime state" do
    {:ok, config, _pid} = setup_deol_realtime()

    # send disarm request
    :ok = Detector.disarm({config})
    assert :realtime == Detector.status({config})

    refute_receive _
  end

  test "alarm event in alarmed state" do
    {:ok, config, pid} = setup_deol_alarmed()

    # send alarm event
    ev = %Event{address: "4", port: 4, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :alarmed == Detector.status({config})

    refute_receive _
  end

  test "tamper event in alarmed state" do
    {:ok, config, pid} = setup_deol_alarmed()

    # send tamper event
    ev = %Event{address: "4", port: 4, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})

    {:stop, %DetectorEv{type: :alarm, address: "4", port: 4}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :tamper, address: "4", port: 4}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "idle event in alarmed state" do
    {:ok, config, pid} = setup_deol_alarmed()

    # send idle event
    ev = %Event{address: "4", port: 4, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :idle == Detector.status({config})

    {:stop, %DetectorEv{type: :alarm, address: "4", port: 4, id: alm_stop_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :idle, address: "4", port: 4, id: alm_start_id}}
    |> assert_receive(5000)

    refute alm_stop_id == alm_start_id

    refute_receive _
  end

  test "arm a sensor in alarmed state" do
    {:ok, config, _pid} = setup_deol_alarmed()
    {:error, :tripped} = Detector.arm({config})
    refute_receive _
  end

  test "idle event on idle sensor when armed" do
    {:ok, config, pid} =
      30
      |> setup_teol(0.001)
      |> arm_teol_idle_sensor

    # send idle event
    ev = %Event{address: "3", port: 3, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :idle_arm == Detector.status({config})

    refute_receive _
  end

  test "tamper event on idle sensor when armed" do
    {:ok, config, pid} =
      30
      |> setup_teol(0.001)
      |> arm_teol_idle_sensor

    # send tamper event
    ev = %Event{address: "3", port: 3, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3, id: idle_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :short, address: "3", port: 3, id: short_ev_id}}
    |> assert_receive(5000)

    refute idle_ev_id == short_ev_id

    refute_receive _
  end

  test "alarm event on idle sensor when armed" do
    {:ok, config, pid} =
      setup_teol()
      |> arm_teol_idle_sensor

    # send alarm event
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :alarmed_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3, id: idle_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :alarm, address: "3", port: 3, id: alarm_ev_id}}
    |> assert_receive(5000)

    refute idle_ev_id == alarm_ev_id

    refute_receive _
  end

  test "alarm event on idle, delayed sensor when armed" do
    {:ok, config, pid} =
      30
      |> setup_teol(0.001)
      |> arm_teol_idle_sensor

    # send alarm event
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :entry_wait == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3, id: idle_ev_id}}
    |> assert_receive(5000)

    {:start, %DetectorEntryEv{address: "3", port: 3, id: entry_ev_id}}
    |> assert_receive(5000)

    refute idle_ev_id == entry_ev_id
    refute entry_ev_id == nil

    refute_receive _
  end

  test "disarm request on idle sensor" do
    {:ok, config, _pid} =
      30
      |> setup_teol(0.001)
      |> arm_teol_idle_sensor

    :ok = Detector.disarm({config})
    assert :idle == Detector.status({config})

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "idle event in exit wait state" do
    {:ok, config, pid} =
      30
      |> setup_teol(30)
      |> exit_wait_teol_sensor

    # send idle event
    ev = %Event{address: "3", port: 3, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :exit_wait == Detector.status({config})

    refute_receive _
  end

  test "tamper event in exit wait state" do
    {:ok, config, pid} =
      30
      |> setup_teol(30)
      |> exit_wait_teol_sensor

    # send tamper event
    ev = %Event{address: "3", port: 3, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorExitEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :fault, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "timeout event in exit wait state" do
    {:ok, config, _pid} =
      30
      |> setup_teol(1)
      |> exit_wait_teol_sensor

    {:stop, %DetectorExitEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    assert :idle_arm == Detector.status({config})

    refute_receive _
  end

  test "disarm request in exit wait state" do
    {:ok, config, _pid} =
      30
      |> setup_teol(1)
      |> exit_wait_teol_sensor

    :ok = Detector.disarm({config})

    {:stop, %DetectorExitEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    assert :idle == Detector.status({config})

    refute_receive _
  end

  test "idle event in entry wait state" do
    {:ok, config, pid} = entry_wait_teol_sensor(30)

    # send idle event
    ev = %Event{address: "3", port: 3, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :entry_wait == Detector.status({config})

    refute_receive _
  end

  test "alarm event in entry wait state" do
    {:ok, config, pid} = entry_wait_teol_sensor(30)

    # send alarm event
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :entry_wait == Detector.status({config})

    refute_receive _
  end

  test "tamper event in entry wait state" do
    {:ok, config, pid} = entry_wait_teol_sensor(30)

    # send tamper event
    ev = %Event{address: "3", port: 3, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorEntryEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :short, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "timeout event in entry wait state" do
    {:ok, config, _pid} = entry_wait_teol_sensor(1)

    {:stop, %DetectorEntryEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :alarm, address: "3", port: 3}}
    |> assert_receive(5000)

    assert :alarmed_arm == Detector.status({config})

    refute_receive _
  end

  test "disarm request in entry wait state" do
    {:ok, config, _pid} = entry_wait_teol_sensor(30)

    :ok = Detector.disarm({config})

    {:stop, %DetectorEntryEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :realtime, address: "3", port: 3}}
    |> assert_receive(5000)

    assert :realtime == Detector.status({config})

    refute_receive _
  end

  test "disarm request in entry wait state for 24h sensor" do
    {:ok, config, _pid} = entry_wait_24h_teol_sensor(30)

    :ok = Detector.disarm({config})

    {:stop, %DetectorEntryEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :alarm, address: "3", port: 3}}
    |> assert_receive(5000)

    assert :alarmed == Detector.status({config})

    refute_receive _
  end

  test "idle event when sensor is tampered and armed" do
    {:ok, config, pid} = tamper_arm_teol_sensor(30)

    # send an idle event
    ev = %Event{address: "3", port: 3, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :idle_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "tamper events when sensor is tampered and armed" do
    {:ok, config, pid} = tamper_arm_teol_sensor(30)

    # send a short tamper event
    ev = %Event{address: "3", port: 3, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :short, address: "3", port: 3}}
    |> assert_receive(5000)

    # send a fault tamper event
    ev = %Event{address: "3", port: 3, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :short, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :fault, address: "3", port: 3}}
    |> assert_receive(5000)

    # send a tamper... tamper event
    ev = %Event{address: "3", port: 3, value: 45}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :fault, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    # and back
    ev = %Event{address: "3", port: 3, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :fault, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "alarm event when sensor is tampered and armed (no delay)" do
    {:ok, config, pid} = tamper_arm_teol_sensor(0)

    # send alarm event
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :alarmed_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :alarm, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "alarm event when sensor is tampered and armed (entry delay)" do
    {:ok, config, pid} = tamper_arm_teol_sensor(1)

    # send alarm event
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :entry_wait == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEntryEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:stop, %DetectorEntryEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :alarm, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "disarm sensor while is tampered" do
    {:ok, config, _pid} = tamper_arm_teol_sensor(1)

    # send disarm request
    :ok = Detector.disarm({config})
    assert :tampered == Detector.status({config})

    {:start, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "idle event when sensor is alarmed and armed" do
    {:ok, config, pid} = alarmed_arm_teol_sensor(false)

    # send an idle event
    ev = %Event{address: "3", port: 3, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :idle_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :alarm, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "tamper event when sensor is alarmed and armed" do
    {:ok, config, pid} = alarmed_arm_teol_sensor(false)

    # send a tamper event
    ev = %Event{address: "3", port: 3, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :alarm, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :short, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "alarm event when sensor is alarmed and armed" do
    {:ok, config, pid} = alarmed_arm_teol_sensor(false)

    # send an alarm event
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :alarmed_arm == Detector.status({config})

    refute_receive _
  end

  test "disarm sensor while is alarmed" do
    {:ok, config, _pid} = alarmed_arm_teol_sensor(false)

    # send disarm request
    :ok = Detector.disarm({config})
    assert :realtime == Detector.status({config})

    {:stop, %DetectorEv{type: :alarm, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :realtime, address: "3", port: 3}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "disarm a 24h sensor while is alarmed" do
    {:ok, config, _pid} = alarmed_arm_teol_sensor(true)

    # send disarm request
    :ok = Detector.disarm({config})
    assert :alarmed == Detector.status({config})

    refute_receive _
  end

  test "Can have multiple subscribers" do
    {:ok, sensor1, pid1} = setup_no("6")
    {:ok, sensor2, pid2} = setup_no("7")

    # send an idle event
    for {pid, config} <- [{pid1, sensor1}, {pid2, sensor2}] do
      ev = %Event{address: config.address, port: 6, value: 15}
      :ok = Process.send(pid, {:event, ev}, [])
      assert :idle == Detector.status({config})
    end

    # send an alarm event
    for {pid, config} <- [{pid1, sensor1}, {pid2, sensor2}] do
      ev = %Event{address: config.address, port: 6, value: 5}
      :ok = Process.send(pid, {:event, ev}, [])
      assert :realtime == Detector.status({config})
    end

    {:stop, %DetectorEv{type: :idle, address: "6", port: 6}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :realtime, address: "6", port: 6}}
    |> assert_receive(5000)

    {:stop, %DetectorEv{type: :idle, address: "7", port: 6}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :realtime, address: "7", port: 6}}
    |> assert_receive(5000)

    refute_receive _
  end

  test "Dead subscriber is removed from listners pool" do
    {:ok, config, pid} = setup_no("6")
    assert :idle == Detector.status({config})

    # send an alarm event
    ev = %Event{address: config.address, port: 6, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :realtime == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "6", port: 6}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :realtime, address: "6", port: 6}}
    |> assert_receive(5000)

    # now we fake a :DOWN event in order to be removed from pool
    down_ev = {:DOWN, make_ref(), :process, self(), :testing}
    Process.send(pid, down_ev, [])

    # got back to idle state
    ev = %Event{address: config.address, port: 6, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :idle == Detector.status({config})

    refute_receive _
  end

  #
  # Private helper functions to keep tests a bit more clear
  #
  defp setup_nc do
    sensor = %SensorModel{
      name: "NCSENSOR",
      balance: "NC",
      th1: 10,
      partitions: [],
      enabled: true,
      address: "1",
      port: 1
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end

  defp setup_no(address) when is_binary(address) do
    sensor = %SensorModel{
      name: "NOSENSOR",
      balance: "NO",
      th1: 10,
      partitions: [],
      enabled: true,
      address: address,
      port: 6
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end

  defp setup_24h_nc do
    sensor = %SensorModel{
      name: "NCSENSOR",
      balance: "NC",
      th1: 10,
      partitions: [],
      enabled: true,
      address: "1",
      port: 1,
      full24h: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end

  defp setup_eol do
    sensor = %SensorModel{
      name: "EOL",
      balance: "EOL",
      th1: 10,
      th2: 20,
      entry_delay: false,
      exit_delay: false,
      partitions: [],
      address: "2",
      port: 2,
      enabled: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end

  defp setup_internal_eol(entry_delay, exit_delay)
       when is_integer(entry_delay) and is_integer(exit_delay) do
    sensor = %SensorModel{
      name: "EOL",
      balance: "EOL",
      th1: 10,
      th2: 20,
      entry_delay: is_integer(entry_delay) and entry_delay > 0,
      exit_delay: is_integer(exit_delay) and exit_delay > 0,
      partitions: [],
      address: "2",
      port: 2,
      enabled: true,
      internal: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {entry_delay, exit_delay})
    {:ok, sensor, pid}
  end

  defp setup_eol(entry_delay, exit_delay)
       when is_integer(entry_delay) and is_integer(exit_delay) do
    sensor = %SensorModel{
      name: "EOL",
      balance: "EOL",
      th1: 10,
      th2: 20,
      entry_delay: is_integer(entry_delay),
      exit_delay: is_integer(exit_delay),
      partitions: [],
      address: "2",
      port: 2,
      enabled: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {entry_delay, exit_delay})
    {:ok, sensor, pid}
  end

  defp setup_deol_alarmed do
    {:ok, config, pid} = setup_24h_deol()

    # put in realtime state
    ev = %Event{address: "4", port: 4, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :alarmed == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "4", port: 4}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :alarm, address: "4", port: 4}}
    |> assert_receive(5000)

    {:ok, config, pid}
  end

  defp setup_deol_realtime do
    {:ok, config, pid} = setup_deol()

    # put in realtime state
    ev = %Event{address: "4", port: 4, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :realtime == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "4", port: 4}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :realtime, address: "4", port: 4}}
    |> assert_receive(5000)

    {:ok, config, pid}
  end

  defp setup_deol do
    sensor = %SensorModel{
      name: "DEOL",
      balance: "DEOL",
      th1: 10,
      th2: 20,
      th3: 30,
      entry_delay: false,
      exit_delay: false,
      partitions: [],
      address: "4",
      port: 4,
      enabled: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end

  defp setup_24h_deol do
    sensor = %SensorModel{
      name: "DEOL",
      balance: "DEOL",
      th1: 10,
      th2: 20,
      th3: 30,
      entry_delay: false,
      exit_delay: false,
      partitions: [],
      address: "4",
      port: 4,
      enabled: true,
      full24h: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end

  defp setup_teol do
    sensor = %SensorModel{
      name: "TEOL",
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

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end

  defp setup_teol(entry_delay, exit_delay)
       when is_number(entry_delay) and is_number(exit_delay) do
    sensor = %SensorModel{
      name: "TEOL",
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
    :ok = Detector.subscribe(pid, {entry_delay, exit_delay})
    {:ok, sensor, pid}
  end

  defp setup_24h_teol(entry_delay, exit_delay)
       when is_number(entry_delay) and is_number(exit_delay) do
    sensor = %SensorModel{
      name: "TEOL",
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
      full24h: true
    }

    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {entry_delay, exit_delay})
    {:ok, sensor, pid}
  end

  defp arm_teol_idle_sensor({:ok, config, pid}) do
    assert :idle == Detector.status({config})

    :ok = Detector.arm({config})
    assert :idle_arm == Detector.status({config})

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    {:ok, config, pid}
  end

  defp exit_wait_teol_sensor({:ok, config, pid}) do
    assert :idle == Detector.status({config})

    :ok = Detector.arm({config})
    assert :exit_wait == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorExitEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:ok, config, pid}
  end

  defp entry_wait_teol_sensor(entry_delay) do
    {:ok, config, pid} = setup_teol(entry_delay, 0)
    assert :idle == Detector.status({config})

    :ok = Detector.arm({config})
    assert :idle_arm == Detector.status({config})

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    # send alarm event to trigger entry timer
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :entry_wait == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEntryEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:ok, config, pid}
  end

  defp entry_wait_24h_teol_sensor(entry_delay) do
    {:ok, config, pid} = setup_24h_teol(entry_delay, 0)
    assert :idle == Detector.status({config})

    :ok = Detector.arm({config})
    assert :idle_arm == Detector.status({config})

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    # send alarm event to trigger entry timer
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :entry_wait == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEntryEv{address: "3", port: 3}}
    |> assert_receive(5000)

    {:ok, config, pid}
  end

  defp tamper_arm_teol_sensor(entry_delay) do
    {:ok, config, pid} = setup_teol(entry_delay, 0)
    assert :idle == Detector.status({config})

    :ok = Detector.arm({config})
    assert :idle_arm == Detector.status({config})

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    # send tamper event to tampered state
    ev = %Event{address: "3", port: 3, value: 45}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :tamper, address: "3", port: 3}}
    |> assert_receive(5000)

    {:ok, config, pid}
  end

  defp alarmed_arm_teol_sensor(is24h) when is_boolean(is24h) do
    {:ok, config, pid} =
      case is24h do
        true -> setup_24h_teol(0, 0)
        false -> setup_teol()
      end

    assert :idle == Detector.status({config})

    # arm it
    :ok = Detector.arm({config})
    assert :idle_arm == Detector.status({config})

    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    # send alarm
    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :alarmed_arm == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :alarm, address: "3", port: 3}}
    |> assert_receive(5000)

    {:ok, config, pid}
  end
end
