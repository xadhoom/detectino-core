defmodule DtCore.Test.Monitor.Detector do
  use ExUnit.Case, async: false

  alias DtCore.Event
  alias DtCore.DetectorEv
  alias DtCore.DetectorExitEv
  alias DtCore.Monitor.Detector

  alias DtWeb.Sensor, as: SensorModel

  test "no alarm but realtime event if NC partion is not armed" do
    {:ok, config, pid} = setup_nc()

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    assert :realtime == Detector.status({config})

    {:start, %DetectorEv{type: :realtime, address: "1", port: 1}}
    |> assert_receive(5000)
  end

  test "alarm event if 24H NC partion is not armed" do
    {:ok, config, pid} = setup_24h_nc()

    ev = %Event{address: "1", port: 1, value: 15}
    :ok = Process.send(pid, {:event, ev}, [])

    assert :alarmed == Detector.status({config})

    {:start, %DetectorEv{type: :alarm, address: "1", port: 1}}
    |> assert_receive(5000)
  end

  test "tamper event on not armed partition" do
    {:ok, config, pid} = setup_eol()

    ev = %Event{address: "1", port: 1, value: 5}
    :ok = Process.send(pid, {:event, ev}, [])

    assert :tampered == Detector.status({config})

    {:stop, %DetectorEv{type: :idle, address: "1", port: 1}}
    |> assert_receive(5000)

    {:start, %DetectorEv{type: :short, address: "1", port: 1}}
    |> assert_receive(5000)
  end

  test "arm a not delayed partition" do
    {:ok, config, _pid} = setup_eol()

    Detector.arm({config})

    {:start, %DetectorEv{type: :idle, address: "2", port: 2}}
    |> assert_receive(5000)

    assert :idle_arm == Detector.status({config})
  end

  test "arm an exit delayed partition" do
    {:ok, config, _pid} = setup_eol(0, 30)

    Detector.arm({config})

    {:stop, %DetectorEv{type: :idle, address: "2", port: 2}}
    |> assert_receive(5000)
    {:start, %DetectorExitEv{address: "2", port: 2}}
    |> assert_receive(5000)

    assert :exit_wait == Detector.status({config})
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
end
