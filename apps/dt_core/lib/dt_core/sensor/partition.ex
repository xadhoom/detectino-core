defmodule DtCore.Sensor.Partition do
  @moduledoc """
  Handles the logic of a Partion
  """
  use GenServer

  require Logger
  alias DtCore.Sensor.Utils
  alias DtWeb.Partition, as: PartitionModel

  def start_link({config = %PartitionModel{}, receiver}) do
    {:ok, name} = Utils.partition_server_name(config)
    GenServer.start_link(__MODULE__, {config, receiver}, name: name)
  end

  def arming_status(config = %PartitionModel{}) do
    config
    |> Utils.partition_server_pid
    |> GenServer.call({:arming_status})
  end

  def init({config, receiver}) do
    Logger.debug("Starting partition worker with " <>
      "#{inspect config} config")
    state = %{
      config: config,
      receiver: receiver
    }
    {:ok, state}
  end

  def handle_call({:arming_status}, _from, state) do
    res = state.config.armed
    {:reply, res, state}
  end
end