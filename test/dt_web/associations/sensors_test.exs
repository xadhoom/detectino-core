defmodule DtWeb.Associations.SensorTest do
  @moduledoc """
  These test just assure us that associations names and types are correct
  """
  use DtWeb.ConnCase

  alias DtCtx.Monitoring.Partition
  alias DtCtx.Monitoring.Sensor

  test "sensors association" do
    sens = Repo.insert!(%Sensor{})
    part1 = Repo.insert!(%Partition{})
    part2 = Repo.insert!(%Partition{})

    sens
    |> Repo.preload(:partitions)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:partitions, [part1, part2]) 
    |> Repo.update!


    s = Repo.one!(Sensor) |> Repo.preload(:partitions)
    assert Enum.count(s.partitions) == 2
    
    tmp = Enum.at(s.partitions, 0)
    assert tmp.id == part1.id

    tmp = Enum.at(s.partitions, 1)
    assert tmp.id == part2.id

    p = Partition |> first |> Repo.one! |> Repo.preload(:sensors)
    assert Enum.count(p.sensors) == 1

    tmp = Enum.at(p.sensors, 0)
    assert tmp.id == sens.id
  end

end
