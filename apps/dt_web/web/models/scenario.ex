defmodule DtWeb.Scenario do
  use DtWeb.Web, :model

  @derive {Poison.Encoder, only: [:id, :name, :enabled]}

  schema "scenarios" do
    field :name, :string
    field :enabled, :boolean, default: false

    timestamps

    has_many :partitions_scenarios, DtWeb.PartitionScenario
    many_to_many :partitions,
      DtWeb.Partition, join_through: DtWeb.PartitionScenario
  end

  @required_fields ~w(name enabled)
  @optional_fields ~w()

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name)
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name)
  end

end
