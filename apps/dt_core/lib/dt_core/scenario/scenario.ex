defmodule DtCore.Scenario do
  use GenServer

  require Logger

  defstruct name: nil,
    model: nil

  #
  # Client APIs
  #
  def start_link(rules, server_name) when is_list(rules) and is_atom(server_name) do
    Logger.debug("Starting Scenario Server with #{inspect rules} rules")
    GenServer.start_link(__MODULE__, {rules}, name: server_name)
  end

  def get_rules(server_name) do
    GenServer.call server_name, {:get_rules}
  end

  #
  # GenServer callbacks
  #
  def init({rules}) do
    Logger.info "Starting Scenarios Server"
    {:ok,
      %{rules: rules}
    }
  end

  def handle_call({:get_rules}, from, state) do
    {:reply, state.rules, state}
  end

end
