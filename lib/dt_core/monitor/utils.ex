defmodule DtCore.Monitor.Utils do
  @moduledoc """
  Various sensor related utils
  """
  alias DtCtx.Monitoring.Partition, as: PartitionModel
  alias DtCtx.Monitoring.Sensor, as: SensorModel

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
    :global.whereis_name(name)
  end

  def sensor_server_name(_sensor = %SensorModel{name: nil}) do
    {:error, :name}
  end

  def sensor_server_name(_sensor = %SensorModel{address: nil}) do
    {:error, :address}
  end

  def sensor_server_name(_sensor = %SensorModel{port: nil}) do
    {:error, :port}
  end

  def sensor_server_name(sensor = %SensorModel{}) do
    name = {
      :sensor,
      name: sensor.name, address: sensor.address, port: sensor.port
    }

    {:ok, {:global, name}}
  end

  def sensor_server_pid(sensor = %SensorModel{}) do
    {:ok, {:global, name}} = sensor_server_name(sensor)
    :global.whereis_name(name)
  end

  def random_id do
    Base.hex_encode32(:crypto.strong_rand_bytes(20), case: :lower)
  end
end
