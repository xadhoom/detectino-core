defmodule DtCore.Output.Worker do
  @moduledoc """
  Output worker server.
  It's dispatched by the Outputs Supervisor and listens
  to all associated events, via the Registry
  """
  use GenServer

  require Logger
  alias DtCore.Output.Utils
  alias DtWeb.Output, as: OutputModel

  #
  # Client APIs
  #
  def start_link({config = %OutputModel{}}) do
    {:ok, name} = Utils.output_server_name(config)
    GenServer.start_link(__MODULE__, {config}, name: name)
  end

  #
  # GenServer callbacks
  #
  def init({config}) do
    Logger.info "Starting Output Worker #{config.name}"
    state = %{config: config}
    {:ok, state}
  end

end
