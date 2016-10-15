defmodule DtCore.Test.Sensor.Worker do
  use DtCore.EctoCase

  alias DtCore.Sensor.Worker
  alias DtWeb.Sensor, as: SensorModel

  alias DtCore.Event, as: Event

  @nc_model %SensorModel{balance: "NC", th1: 10}
  @no_model %SensorModel{balance: "NO", th1: 10}
  @eol_model %SensorModel{balance: "EOL", th1: 10, th2: 20}
  @deol_model %SensorModel{balance: "DEOL", th1: 10, th2: 20, th3: 30}
  @teol_model %SensorModel{balance: "TEOL", th1: 10, th2: 20, th3: 30, th4: 40}

  test "standby values should fail if no data" do
    state = %{config: %SensorModel{}}

    ev = %Event{}
    |> Worker.process_event(state)

    assert {:error, state} == ev
  end

  test "NC normal, standby status" do
    state = %{config: @nc_model}

    ev = %Event{address: "1", port: 1, value: 5}
    |> Worker.process_event(state)

    assert {:standby_1_1, state} == ev
  end

  test "NC alarm status" do
    state = %{config: @nc_model}

    ev = %Event{address: "1", port: 1, value: 15}
    |> Worker.process_event(state)

    assert {:alarm_1_1, state} == ev
  end

  test "NO normal, standby status" do
    state = %{config: @no_model}

    ev = %Event{address: "1", port: 1, value: 15}
    |> Worker.process_event(state)

    assert {:standby_1_1, state} == ev
  end

  test "NO alarm status" do
    state = %{config: @no_model}

    ev = %Event{address: "1", port: 1, value: 5}
    |> Worker.process_event(state)

    assert {:alarm_1_1, state} == ev
  end

  test "EOL normal, standby status" do
    state = %{config: @eol_model}

    ev = %Event{address: "1", port: 1, value: 15}
    |> Worker.process_event(state)

    assert {:standby_1_1, state} == ev
  end

  test "EOL alarm status" do
    state = %{config: @eol_model}

    ev = %Event{address: "1", port: 1, value: 25}
    |> Worker.process_event(state)

    assert {:alarm_1_1, state} == ev
  end

  test "EOL short status" do
    state = %{config: @eol_model}

    ev = %Event{address: "1", port: 1, value: 2}
    |> Worker.process_event(state)

    assert {:short_1_1, state} == ev
  end

  test "DEOL normal, standby status" do
    state = %{config: @deol_model}

    ev = %Event{address: "1", port: 1, value: 15}
    |> Worker.process_event(state)

    assert {:standby_1_1, state} == ev
  end

  test "DEOL tamper alarm" do
    state = %{config: @deol_model}

    ev = %Event{address: "1", port: 1, value: 35}
    |> Worker.process_event(state)

    assert {:tamper_1_1, state} == ev
  end

  test "DEOL fault alarm" do
    # since fault is available only on TEOL
    # fault is mapped to tamper on DEOL
    state = %{config: @deol_model}

    ev = %Event{address: "1", port: 1, value: 45}
    |> Worker.process_event(state)

    assert {:tamper_1_1, state} == ev
  end

  test "DEOL shorted alarm" do
    state = %{config: @deol_model}

    ev = %Event{address: "1", port: 1, value: 5}
    |> Worker.process_event(state)

    assert {:short_1_1, state} == ev    
  end

  test "DEOL alarm alarm" do
    state = %{config: @deol_model}

    ev = %Event{address: "1", port: 1, value: 25}
    |> Worker.process_event(state)

    assert {:alarm_1_1, state} == ev 
  end

  test "TEOL short" do
    # this is available only on TEOL zones
    state = %{config: @teol_model}

    ev = %Event{address: "1", port: 1, value: 5}
    |> Worker.process_event(state)

    assert {:short_1_1, state} == ev    
  end

  test "TEOL idle" do
    # this is available only on TEOL zones
    state = %{config: @teol_model}

    ev = %Event{address: "1", port: 1, value: 15}
    |> Worker.process_event(state)

    assert {:standby_1_1, state} == ev    
  end

  test "TEOL alarm alarm" do
    # this is available only on TEOL zones
    state = %{config: @teol_model}

    ev = %Event{address: "1", port: 1, value: 25}
    |> Worker.process_event(state)

    assert {:alarm_1_1, state} == ev    
  end

  test "TEOL fault alarm" do
    # this is available only on TEOL zones
    state = %{config: @teol_model}

    ev = %Event{address: "1", port: 1, value: 35}
    |> Worker.process_event(state)

    assert {:fault_1_1, state} == ev    
  end

  test "TEOL tamper alarm" do
    # this is available only on TEOL zones
    state = %{config: @teol_model}

    ev = %Event{address: "1", port: 1, value: 45}
    |> Worker.process_event(state)

    assert {:tamper_1_1, state} == ev    
  end

end
