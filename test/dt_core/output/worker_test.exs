defmodule DtCore.Test.Output.Worker do
  use DtCtx.DataCase

  alias DtBus.ActionRegistry
  alias DtCore.Monitor.Sup
  alias DtCore.Monitor.Utils
  alias DtCtx.Outputs.Output, as: OutputModel
  alias DtCtx.Outputs.Event, as: EventModel
  alias DtCtx.Outputs.EmailSettings, as: EmailSettingsModel
  alias DtCtx.Outputs.BusSettings, as: BusSettingsModel
  alias DtCore.OutputsRegistry
  alias DtCore.Output.Worker
  alias DtCore.Test.TimerHelper
  alias DtCore.DetectorEv
  alias DtCore.DetectorEntryEv
  alias DtCore.PartitionEv
  alias DtCore.ArmEv
  alias Swoosh.Email
  alias DtCore.Output.Actions.Email, as: EmailConfig

  setup_all do
    {:ok, _} = Registry.start_link(:duplicate, OutputsRegistry.registry)
    :meck.new(Etimer, [:passthrough])
    :meck.expect(Etimer, :start_timer,
      fn(_, _, _ , _) ->
        0
      end)
    :ok
  end

  setup do
    {:ok, _pid} = Sup.start_link()

    on_exit fn ->
      TimerHelper.wait_until fn ->
        assert Process.whereis(:output_server) == nil
        assert Process.whereis(Sup) == nil
      end
    end

    :ok
  end

  test "disabled worker does not listens to associated events" do
    events = [
      %EventModel{
        source: "partition",
        source_config: Poison.encode!(%{
          name: "area one", type: "alarm"
        })
      },
      %EventModel{
        source: "sensor",
        source_config: Poison.encode!(%{
          address: "10", port: 5, type: "alarm"
        })
      }
    ]
    output = %OutputModel{name: "another output", events: events, enabled: false}

    {:ok, pid} = Worker.start_link({output})

    listeners = Registry.keys(OutputsRegistry.registry, pid)
    assert Enum.count(listeners) == 0
  end

  test "worker listens to associated events" do
    events = [
      %EventModel{
        source: "arming",
        source_config: Poison.encode!(%{
          name: "area one"
        })
      },
      %EventModel{
        source: "partition",
        source_config: Poison.encode!(%{
          name: "area one", type: "alarm"
        })
      },
      %EventModel{
        source: "sensor",
        source_config: Poison.encode!(%{
          address: "10", port: 5, type: "alarm"
        })
      }
    ]
    output = %OutputModel{name: "an output", events: events, enabled: true}

    {:ok, pid} = Worker.start_link({output})

    listeners = Registry.keys(OutputsRegistry.registry, pid)
    assert Enum.count(listeners) == 3

    key = %{source: :partition, name: "area one", type: :alarm}
    listeners = Registry.lookup(OutputsRegistry.registry, key)
    assert Enum.count(listeners) == 1

    key = %{source: :sensor, address: "10", port: 5, type: :alarm}
    listeners = Registry.lookup(OutputsRegistry.registry, key)
    assert Enum.count(listeners) == 1

    key = %{source: :arming, name: "area one"}
    listeners = Registry.lookup(OutputsRegistry.registry, key)
    assert Enum.count(listeners) == 1
  end

  test "emails are sent on alarm event" do
    events = [
      %EventModel{
        source: "arming",
        source_config: Poison.encode!(%{
          name: "area one"
        })
      },
      %EventModel{
        source: "partition",
        source_config: Poison.encode!(%{
          name: "area one", type: "alarm"
        })
      },
      %EventModel{
        source: "sensor",
        source_config: Poison.encode!(%{
          address: "10", port: 5, type: "alarm"
        })
      }
    ]
    output = %OutputModel{
      name: "email test output",
      events: events,
      type: "email",
      enabled: true,
      email_settings: %EmailSettingsModel{
        to: "test@example.com",
        from: "bob@example.com"
      }
    }

    # testing the server callbacks here
    # since the swoosh test adapter sends
    # emails to the current process
    {:ok, state} = Worker.init({output})

    s_ev = {:start, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    p_ev = {:start, %PartitionEv{type: :alarm, name: "area one", id: Utils.random_id()}}
    s_ev_end = {:stop, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    p_ev_end = {:stop, %PartitionEv{type: :alarm, name: "area one", id: Utils.random_id()}}
    arm_start = {:start, %ArmEv{name: "area one", initiator: "admin", id: Utils.random_id()}}
    arm_stop = {:stop, %ArmEv{name: "area one", initiator: "admin", id: Utils.random_id()}}

    s_ev_delayed = {:start,
      %DetectorEntryEv{address: "10", port: 5, id: Utils.random_id()}}

    Worker.handle_info(s_ev, state)
    get_subject(:sensor_start) |> assert_email

    Worker.handle_info(p_ev, state)
    get_subject(:partition_start) |> assert_email

    Worker.handle_info(s_ev_end, state)
    get_subject(:sensor_end) |> assert_email

    Worker.handle_info(p_ev_end, state)
    get_subject(:partition_end) |> assert_email

    Worker.handle_info(s_ev_delayed, state)
    get_delayed_subject(:sensor_start) |> assert_email(true)

    Worker.handle_info(arm_start, state)
    subj = get_subject(:arm_start)
    assert_received {:email, %Email{subject: ^subj}}

    Worker.handle_info(arm_stop, state)
    subj = get_subject(:arm_end)
    assert_received {:email, %Email{subject: ^subj}}
  end

  test "monostable output on time" do
    events = [
      %EventModel{
        source: "sensor",
        source_config: Poison.encode!(%{
          address: "10", port: 5, type: "alarm"
        })
      }
    ]
    output = %OutputModel{
      name: "an output",
      events: events,
      enabled: true,
      type: "bus",
      bus_settings: %BusSettingsModel{
        type: "monostable",
        mono_ontime: 30,
        address: "addr", port: 42
      }
    }
    {:ok, pid} = Worker.start_link({output})
    assert :meck.called(Etimer, :start_link, :_)

    ActionRegistry.registry
    |> Registry.register(:bus_commands, [])

    ev = {:start, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    Process.send(pid, ev, [])

    %DtBus.OutputAction{
      command: :on,
      address: "addr", port: 42
    }
    |> assert_receive(5000)

    TimerHelper.wait_until fn ->
      assert :meck.called(
        Etimer, :start_timer,
        [:_, :_, 30_000, {Worker, :timer_expiry, [:mono_expiry, output]}])
    end

    # a stop event should do nothing
    ev = {:stop, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    Process.send(pid, ev, [])
    _msg |> refute_receive(1000)

    Worker.timer_expiry({:mono_expiry, output})

    %DtBus.OutputAction{
      command: :off,
      address: "addr", port: 42
    }
    |> assert_receive(5000)

  end

  test "monostable output off time" do
    events = [
      %EventModel{
        source: "sensor",
        source_config: Poison.encode!(%{
          address: "10", port: 5, type: "alarm"
        })
      }
    ]
    output = %OutputModel{
      name: "an output",
      events: events,
      enabled: true,
      type: "bus",
      bus_settings: %BusSettingsModel{
        type: "monostable",
        mono_ontime: 30,
        mono_offtime: 120,
        address: "addr", port: 42
      }
    }
    {:ok, pid} = Worker.start_link({output})
    assert :meck.called(Etimer, :start_link, :_)

    ActionRegistry.registry
    |> Registry.register(:bus_commands, [])

    ev = {:start, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    Process.send(pid, ev, [])

    %DtBus.OutputAction{
      command: :on,
      address: "addr", port: 42
    }
    |> assert_receive(5000)

    TimerHelper.wait_until fn ->
      assert :meck.called(
        Etimer, :start_timer,
        [:_, :_, 30_000, {Worker, :timer_expiry, [:mono_expiry, output]}])
    end

    Worker.timer_expiry({:mono_expiry, output})

    %DtBus.OutputAction{
      command: :off,
      address: "addr", port: 42
    }
    |> assert_receive(5000)

    TimerHelper.wait_until fn ->
      assert :meck.called(
        Etimer, :start_timer,
        [:_, :_, 120_000, {Worker, :timer_expiry, [:mono_off_expiry, output]}])
    end

    # now another event should not run because we're in offtime
    ev = {:start, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    Process.send(pid, ev, [])
    %DtBus.OutputAction{}
    |> refute_receive(1000)

    Worker.timer_expiry({:mono_off_expiry, output})

    ev = {:start, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    Process.send(pid, ev, [])
    %DtBus.OutputAction{}
    |> assert_receive(1000)
  end

  test "bistable output" do
    events = [
      %EventModel{
        source: "sensor",
        source_config: Poison.encode!(%{
          address: "10", port: 5, type: "alarm"
        })
      }
    ]
    output = %OutputModel{
      name: "an output",
      events: events,
      enabled: true,
      type: "bus",
      bus_settings: %BusSettingsModel{
        type: "bistable",
        mono_ontime: 1,
        mono_offtime: 120,
        address: "addr", port: 42
      }
    }
    {:ok, pid} = Worker.start_link({output})
    assert :meck.called(Etimer, :start_link, :_)

    ActionRegistry.registry
    |> Registry.register(:bus_commands, [])

    ev = {:start, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    Process.send(pid, ev, [])

    %DtBus.OutputAction{
      command: :on,
      address: "addr", port: 42
    }
    |> assert_receive(5000)

    TimerHelper.wait_until fn ->
      refute :meck.called(
        Etimer, :start_timer,
        [:_, :_, 1000, {Worker, :timer_expiry, [:mono_expiry, output]}])
    end

    %DtBus.OutputAction{
      command: :off,
      address: "addr", port: 42
    }
    |> refute_receive(1000)

    TimerHelper.wait_until fn ->
      refute :meck.called(
        Etimer, :start_timer,
        [:_, :_, 120_000, {Worker, :timer_expiry, [:mono_off_expiry, output]}])
    end

    ev = {:stop, %DetectorEv{type: :alarm, address: "10", port: 5, id: Utils.random_id()}}
    Process.send(pid, ev, [])

    %DtBus.OutputAction{
      command: :off,
      address: "addr", port: 42
    }
    |> assert_receive(5000)
  end

  defp assert_email(subject, delayed \\ false) do
    assert_received {
      :email,
      %Email{
        subject: ^subject,
        private: %{
          delayed_event: ^delayed
        }
      }
    }
  end

  defp get_subject(which) when is_atom(which) do
    :detectino
    |> Application.get_env(EmailConfig.Alarm)
    |> Keyword.get(which)
  end

  defp get_delayed_subject(which) when is_atom(which) do
    :detectino
    |> Application.get_env(EmailConfig.DelayedAlarm)
    |> Keyword.get(which)
  end

end
