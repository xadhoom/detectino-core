defmodule DtWeb.PartitionSensor do
  use DtWeb.Web, :model

  schema "partitions_sensors" do
    belongs_to :partition, Partition
    belongs_to :sensor, Sensor

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:partition_id, :sensor_id])
    |> validate_required([:partition_id, :sensor_id])
  end
end
