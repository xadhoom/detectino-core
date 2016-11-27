defmodule DtCore.Test.Output.Server do
  use DtCore.EctoCase

  alias DtCore.Output.Sup
  alias DtCore.Output.Server
  alias DtWeb.Event, as: EventModel
  alias DtWeb.Output, as: OutputModel
  alias DtCore.Test.TimerHelper
  alias DtWeb.ReloadRegistry

  setup do
    {:ok, _pid} = Sup.start_link

    on_exit fn ->
      TimerHelper.wait_until fn ->
        assert Process.whereis(:output_server) == nil
      end
    end

    :ok
  end

  test "One event without outputs starts nothing" do
    %EventModel{name: "a"}
    |> Repo.insert!

    assert :ok == Server.reload
  
    TimerHelper.wait_until fn ->
      assert {:ok, 0} == Server.outputs
    end
  end

  test "One event with one output starts one worker (reload via client api)" do
    evm = %EventModel{name: "a", source: "sensor"}
    |> Repo.insert!
    |> Repo.preload(:outputs)

    %OutputModel{name: "im an output"}
    |> Repo.insert!
    |> Repo.preload(:events)
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(:events, [evm])
    |> Repo.update!

    assert :ok == Server.reload
  
    TimerHelper.wait_until fn ->
      assert {:ok, 1} == Server.outputs
    end
  end

  test "One event with one output starts one worker (reload via Registry msg)" do
    evm = %EventModel{name: "a", source: "sensor"}
    |> Repo.insert!
    |> Repo.preload(:outputs)

    %OutputModel{name: "im an output"}
    |> Repo.insert!
    |> Repo.preload(:events)
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(:events, [evm])
    |> Repo.update!

    Registry.dispatch(ReloadRegistry.registry, ReloadRegistry.key,
      fn listeners ->
        for {pid, _} <- listeners, do: send(pid, {:reload})
      end)
  
    TimerHelper.wait_until fn ->
      assert {:ok, 1} == Server.outputs
    end
  end

  test "Server listens to reload event" do
    pid = Process.whereis(:output_server)

    # Since the startup is async, we do not have the listener immediately
    TimerHelper.wait_until fn ->
      listeners = Registry.keys(ReloadRegistry.registry, pid)
      assert Enum.count(listeners) == 1
    end
  end

end
