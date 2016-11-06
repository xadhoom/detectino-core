defmodule DtCore.Test.Output.Worker do
  use DtCore.EctoCase

  import Swoosh.TestAssertions

  alias DtCore.Sup
  alias DtWeb.Output, as: OutputModel
  alias DtWeb.Event, as: EventModel
  alias DtWeb.EmailSettings, as: EmailSettingsModel
  alias DtCore.EvRegistry
  alias DtCore.Output.Worker
  alias DtCore.Test.TimerHelper
  alias DtCore.SensorEv
  alias DtCore.PartitionEv


  setup do
    {:ok, _pid} = Sup.start_link
    
    on_exit fn ->
      TimerHelper.wait_until fn ->
        assert Process.whereis(:output_server) == nil
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
    
    listeners = Registry.keys(EvRegistry.registry, pid)
    assert Enum.count(listeners) == 0
  end

  test "worker listens to associated events" do
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
    output = %OutputModel{name: "an output", events: events, enabled: true}

    {:ok, pid} = Worker.start_link({output})
    
    listeners = Registry.keys(EvRegistry.registry, pid)
    assert Enum.count(listeners) == 2

    key = %{source: :partition, name: "area one", type: :alarm}
    listeners = Registry.lookup(EvRegistry.registry, key)
    assert Enum.count(listeners) == 1

    key = %{source: :sensor, address: "10", port: 5, type: :alarm}
    listeners = Registry.lookup(EvRegistry.registry, key)
    assert Enum.count(listeners) == 1
  end

  test "emails are sent after an alarm event" do
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
    
    s_ev = %SensorEv{type: :alarm, address: "10", port: 5}
    p_ev = %PartitionEv{type: :alarm, name: "area one"}

    Worker.handle_info(s_ev, state)
    assert_email_sent subject: "Sensor Alarm"

    Worker.handle_info(p_ev, state)
    assert_email_sent subject: "Partition Alarm"
  end

end
