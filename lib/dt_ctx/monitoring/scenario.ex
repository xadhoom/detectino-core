defmodule DtCtx.Monitoring.Scenario do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :enabled]}

  schema "scenarios" do
    field(:name, :string)
    field(:enabled, :boolean, default: false)

    timestamps()

    has_many(:partitions_scenarios, DtCtx.Monitoring.PartitionScenario)

    many_to_many(
      :partitions,
      DtCtx.Monitoring.Partition,
      join_through: DtCtx.Monitoring.PartitionScenario
    )
  end

  @required_fields [:name, :enabled]
  @optional_fields []

  def create_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
  end
end
