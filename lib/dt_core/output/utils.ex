defmodule DtCore.Output.Utils do
  @moduledoc """
  Various outputs related utild
  """
  alias DtWeb.Output, as: OutputModel

  require Logger

  def output_server_name(_ = %OutputModel{name: nil}) do
    {:error, :name}
  end

  def output_server_name(output = %OutputModel{}) do
    name = {
      :output,
      name: output.name
    }
    {:ok, {:global, name}}
  end

  def output_server_pid(output = %OutputModel{}) do
    {:ok, {:global, name}} = output_server_name(output)
    :global.whereis_name name
  end
end
