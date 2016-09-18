defmodule DtWeb.PartitionScenario do
  use DtWeb.Web, :model

  schema "partitions_scenarios" do
    belongs_to :partition, Partition
    belongs_to :scenario, Sensor

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:partition_id, :scenario_id])
    |> validate_required([:partition_id, :scenario_id])
  end
end
