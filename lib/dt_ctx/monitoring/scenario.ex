defmodule DtCtx.Monitoring.Scenario do
  use DtWeb.Web, :model

  @derive {Poison.Encoder, only: [:id, :name, :enabled]}

  schema "scenarios" do
    field :name, :string
    field :enabled, :boolean, default: false

    timestamps()

    has_many :partitions_scenarios, DtCtx.Monitoring.PartitionScenario
    many_to_many :partitions,
      DtCtx.Monitoring.Partition, join_through: DtCtx.Monitoring.PartitionScenario
  end

  @required_fields ~w(name enabled)
  @optional_fields ~w()
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)

  def create_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@validate_required)
    |> unique_constraint(:name)
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@validate_required)
    |> unique_constraint(:name)
  end

end
