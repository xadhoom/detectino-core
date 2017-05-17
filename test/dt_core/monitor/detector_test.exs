defmodule DtCore.Test.Monitor.Detector do
  use ExUnit.Case, async: false

  alias DtCore.Event
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.Monitor.Detector

  alias DtWeb.Sensor, as: SensorModel

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
    {:start, %DetectorEv{type: :short, address: "3", port: 3}}
    |> assert_receive(5000)

    ev = %Event{address: "3", port: 3, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :idle == Detector.status({config})
    {:stop, %DetectorEv{type: :short, address: "3", port: 3}}
    |> assert_receive(5000)
    {:start, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)

    ev = %Event{address: "3", port: 3, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :realtime == Detector.status({config})
    {:stop, %DetectorEv{type: :idle, address: "3", port: 3}}
    |> assert_receive(5000)
    {:start, %DetectorEv{type: :realtime, address: "3", port: 3}}
    |> assert_receive(5000)

    ev = %Event{address: "3", port: 3, value: 35}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})
    {:stop, %DetectorEv{type: :realtime, address: "3", port: 3}}
    |> assert_receive(5000)
    {:start, %DetectorEv{type: :fault, address: "3", port: 3}}
    |> assert_receive(5000)

    ev = %Event{address: "3", port: 3, value: 45}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :tampered == Detector.status({config})
    {:stop, %DetectorEv{type: :fault, address: "3", port: 3}}
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

  test "arm an exit delayed sensor" do
    {:ok, config, _pid} = setup_eol(0, 30)

    Detector.arm({config})

    {:stop, %DetectorEv{type: :idle, address: "2", port: 2}}
    |> assert_receive(5000)
    {:start, %DetectorExitEv{address: "2", port: 2}}
    |> assert_receive(5000)

    assert :exit_wait == Detector.status({config})
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
    {:start, %DetectorEv{type: :tamper, address: "4", port: 4}}
    |> assert_receive(5000)

    ev = %Event{address: "4", port: 4, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :realtime == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "4", port: 4}}
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
    {:start, %DetectorEv{type: :tamper, address: "4", port: 4}}
    |> assert_receive(5000)

    ev = %Event{address: "4", port: 4, value: 25}
    :ok = Process.send(pid, {:event, ev}, [])
    assert :alarmed == Detector.status({config})

    {:stop, %DetectorEv{type: :tamper, address: "4", port: 4}}
    |> assert_receive(5000)
    {:start, %DetectorEv{type: :alarm, address: "4", port: 4}}
    |> assert_receive(5000)

    refute_receive _
  end

  defp setup_nc do
    sensor = %SensorModel{name: "NCSENSOR", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1}
    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end

  defp setup_24h_nc do
    sensor = %SensorModel{name: "NCSENSOR", balance: "NC", th1: 10,
      partitions: [], enabled: true, address: "1", port: 1, full24h: true}
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
      address: "2", port: 2,
      enabled: true
    }
    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
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
      address: "2", port: 2,
      enabled: true
    }
    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {entry_delay, exit_delay})
    {:ok, sensor, pid}
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
      address: "4", port: 4,
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
      address: "4", port: 4,
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
      address: "3", port: 3,
      enabled: true
    }
    {:ok, pid} = Detector.start_link({sensor})
    :ok = Detector.subscribe(pid, {0, 0})
    {:ok, sensor, pid}
  end
end
