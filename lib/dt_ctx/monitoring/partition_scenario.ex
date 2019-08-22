defmodule DtCtx.Monitoring.PartitionScenario do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :mode, :partition_id, :scenario_id]}

  schema "partitions_scenarios" do
    field(:mode, :string)
    belongs_to(:partition, DtCtx.Monitoring.Partition)
    belongs_to(:scenario, DtCtx.Monitoring.Sensor)

    timestamps()
  end

  @valid_modes ["ARM", "ARMSTAY", "ARMSTAYIMMEDIATE", "DISARM", "NONE"]

  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:mode, :partition_id, :scenario_id])
    |> validate_required([:mode, :partition_id, :scenario_id])
    |> check_modes
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:mode, :partition_id, :scenario_id])
    |> validate_required([:mode, :partition_id, :scenario_id])
    |> check_modes
  end

  def check_modes(changeset) do
    changeset
    |> validate_inclusion(:mode, @valid_modes)
  end
end
