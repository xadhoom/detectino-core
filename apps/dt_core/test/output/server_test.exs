defmodule DtCore.Test.Output.Server do
  use DtCore.EctoCase

  alias DtCore.Output.Sup
  alias DtCore.Output.Server
  alias DtWeb.Event, as: EventModel
  alias DtWeb.Output, as: OutputModel
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

  test "One event without outputs starts nothing" do
    %EventModel{name: "a"}
    |> Repo.insert!

    assert :ok == Server.reload
  
    TimerHelper.wait_until fn ->
      assert {:ok, 0} == Server.outputs
    end
  end

  test "One event with one output starts one worker" do
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

end
