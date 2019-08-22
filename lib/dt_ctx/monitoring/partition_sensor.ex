defmodule DtCtx.Monitoring.PartitionSensor do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "partitions_sensors" do
    belongs_to(:partition, DtCtx.Monitoring.Partition)
    belongs_to(:sensor, DtCtx.Monitoring.Sensor)

    timestamps()
  end

  @required_fields [:partition_id, :sensor_id]

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
