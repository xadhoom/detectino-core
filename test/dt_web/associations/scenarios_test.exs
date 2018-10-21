defmodule DtWeb.Associations.ScenarioTest do
  @moduledoc """
  These test just assure us that associations names and types are correct
  """

  use DtWeb.ConnCase

  alias DtCtx.Monitoring.Partition
  alias DtCtx.Monitoring.Scenario

  test "scenarios association" do
    scene = Repo.insert!(%Scenario{})
    part1 = Repo.insert!(%Partition{})
    part2 = Repo.insert!(%Partition{})

    scene
    |> Repo.preload(:partitions)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:partitions, [part1, part2])
    |> Repo.update!()

    s = Scenario |> Repo.one!() |> Repo.preload(:partitions)
    assert Enum.count(s.partitions) == 2

    tmp = Enum.at(s.partitions, 0)
    assert tmp.id == part1.id

    tmp = Enum.at(s.partitions, 1)
    assert tmp.id == part2.id
  end

  test "scenarios association with partitions_scenarios" do
    scene = Repo.insert!(%Scenario{})
    part1 = Repo.insert!(%Partition{})
    part2 = Repo.insert!(%Partition{})

    scene
    |> Repo.preload(:partitions)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:partitions, [part1, part2])
    |> Repo.update!()

    s = Scenario |> Repo.one!() |> Repo.preload(:partitions_scenarios)
    assert Enum.count(s.partitions_scenarios) == 2

    tmp = Enum.at(s.partitions_scenarios, 0)
    assert tmp.partition_id == part1.id

    tmp = Enum.at(s.partitions_scenarios, 0)
    assert tmp.partition_id == part1.id
  end
end
