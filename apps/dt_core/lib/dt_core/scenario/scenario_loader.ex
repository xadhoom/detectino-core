defmodule DtCore.ScenarioLoader do
  use GenServer

  require Logger

  alias DtWeb.Repo, as: Repo
  alias DtWeb.Scenario, as: ScenarioModel

  alias DtCore.Scenario
  alias DtCore.ScenarioSup

  #
  # Client APIs
  #
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def initialize do
    GenServer.call __MODULE__, {:initialize}, 10000
  end

  #
  # GenServer callbacks
  #
  def init(_) do
    Logger.info "Starting Scenario Loader"
    {:ok, nil}
  end

  def handle_call({:initialize}, from, state) do
    ScenarioSup.stopall
    scenarios = Repo.all(ScenarioModel)
    Enum.each(scenarios, fn(scenario) ->
      case scenario.enabled do
        true -> %Scenario{name: scenario.name, model: scenario}
                |> ScenarioSup.start
        _v -> nil
      end
    end)
    {:reply, :nil, state}
  end

end
