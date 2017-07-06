defmodule DtCtx.Monitoring.PartitionSensor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "partitions_sensors" do
    belongs_to :partition, DtCtx.Monitoring.Partition
    belongs_to :sensor, DtCtx.Monitoring.Sensor

    timestamps()
  end

  @required_fields ~w(partition_id sensor_id)
  @validate_required Enum.map(@required_fields, fn(x) -> String.to_atom(x) end)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@validate_required)
  end
end
