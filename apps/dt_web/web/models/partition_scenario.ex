defmodule DtWeb.PartitionScenario do
  use DtWeb.Web, :model

  @derive {Poison.Encoder, only: [:id, :mode, :partition_id, :scenario_id]}

  schema "partitions_scenarios" do
    field :mode, :string
    belongs_to :partition, Partition
    belongs_to :scenario, Sensor

    timestamps()
  end

  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:mode, :partition_id, :scenario_id])
    |> validate_required([:mode, :partition_id, :scenario_id])
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:mode, :partition_id, :scenario_id])
    |> validate_required([:mode, :partition_id, :scenario_id])
  end

end
