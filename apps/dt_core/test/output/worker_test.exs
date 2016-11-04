defmodule DtCore.Test.Output.Worker do
  use DtCore.EctoCase

  alias DtCore.Sup
  alias DtWeb.Output, as: OutputModel
  alias DtWeb.Event, as: EventModel
  alias DtCore.EvRegistry
  alias DtCore.Output.Worker
  alias DtCore.Test.TimerHelper


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

end
