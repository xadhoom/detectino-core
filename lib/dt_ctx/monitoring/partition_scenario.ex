defmodule DtCtx.Monitoring.PartitionScenario do
  use DtWeb.Web, :model

  @derive {Poison.Encoder, only: [:id, :mode, :partition_id, :scenario_id]}

  schema "partitions_scenarios" do
    field :mode, :string
    belongs_to :partition, Partition
    belongs_to :scenario, Sensor

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
