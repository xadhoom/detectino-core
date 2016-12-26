defmodule DtCore.Sensor.Utils do
  @moduledoc """
  Various sensor related utild
  """
  alias DtWeb.Sensor, as: SensorModel
  alias DtWeb.Partition, as: PartitionModel

  require Logger

  def partition_server_name(_part = %PartitionModel{name: nil}) do
    {:error, :name}
  end

  def partition_server_name(part = %PartitionModel{}) do
    name = {
      :partition,
      name: part.name
    }
    {:ok, {:global, name}}
  end

  def partition_server_pid(part = %PartitionModel{}) do
    {:ok, {:global, name}} = partition_server_name(part)
    :global.whereis_name name
  end

  def sensor_server_name(_sensor = %SensorModel{name: nil}, _partition) do
    {:error, :name}
  end

  def sensor_server_name(_sensor = %SensorModel{address: nil}, _partition) do
    {:error, :address}
  end

  def sensor_server_name(_sensor = %SensorModel{port: nil}, _partition) do
    {:error, :port}
  end

  def sensor_server_name(sensor = %SensorModel{}, partition = %PartitionModel{}) do
    name = {
      :sensor,
      partition: partition.name,
      name: sensor.name,
      address: sensor.address,
      port: sensor.port
    }
    {:ok, {:global, name}}
  end

  def sensor_server_pid(sensor = %SensorModel{}, partition) do
    {:ok, {:global, name}} = sensor_server_name(sensor, partition)
    :global.whereis_name name
  end
end
