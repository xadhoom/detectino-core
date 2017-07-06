defmodule DtWeb.Associations.PartitionTest do
  @moduledoc """
  These test just assure us that associations names and types are correct
  """

  use DtWeb.ConnCase

  alias DtCtx.Monitoring.Partition
  alias DtCtx.Monitoring.Sensor
  alias DtCtx.Monitoring.Scenario

  test "sensors association" do
    part = Repo.insert!(%Partition{})
    sens1 = Repo.insert!(%Sensor{})
    sens2 = Repo.insert!(%Sensor{})

    part
    |> Repo.preload(:sensors)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:sensors, [sens1, sens2]) 
    |> Repo.update!


    p = Repo.one!(Partition) |> Repo.preload(:sensors)
    assert Enum.count(p.sensors) == 2
    
    tmp = Enum.at(p.sensors, 0)
    assert tmp.id == sens1.id

    tmp = Enum.at(p.sensors, 1)
    assert tmp.id == sens2.id
  end

  test "scenarios association" do
    part = Repo.insert!(%Partition{})
    scene1 = Repo.insert!(%Scenario{})
    scene2 = Repo.insert!(%Scenario{})

    part
    |> Repo.preload(:scenarios)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:scenarios, [scene1, scene2]) 
    |> Repo.update!


    p = Repo.one!(Partition) |> Repo.preload(:scenarios)
    assert Enum.count(p.scenarios) == 2
    
    tmp = Enum.at(p.scenarios, 0)
    assert tmp.id == scene1.id

    tmp = Enum.at(p.scenarios, 1)
    assert tmp.id == scene2.id
  end
end
