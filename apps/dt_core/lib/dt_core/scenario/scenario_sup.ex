defmodule DtCore.ScenarioSup do
  use Supervisor

  alias DtWeb.Repo
  import Ecto.Model
  import Ecto.Query, only: [from: 2]

  alias DtCore.Scenario
  alias DtCore.ScenarioLoader

  alias DtWeb.Scenario, as: ScenarioModel

  require Logger

  #
  # Client APIs
  #
  def start_link do
    Supervisor.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def start(scenario = %Scenario{}) do
    rules = load_rules(scenario)
    Logger.debug("Got rules #{inspect rules} for scenario #{inspect scenario.name}")
    child_name = get_child_name(scenario)
    child = worker(Scenario, [rules, child_name], id: child_name, restart: :transient)
    Supervisor.start_child(__MODULE__, child)
  end
  
  def start(scenarios) when is_list(scenarios) do
    Enum.each(scenarios, fn(scenario) -> start(scenario) end)
  end

  def get_worker_by_def(scenario = %Scenario{}) do
    child_id = get_child_name(scenario)
    found = Supervisor.which_children(__MODULE__)
    |> Enum.find( fn(item) ->
          case item do
            {^child_id, _child, _type, _modules} -> true
            _ -> false
          end
        end
      )
    case found do
      {^child_id, pid, _, _} -> pid
      _ -> nil
    end
  end

  defp load_rules(scenario = %Scenario{}) do
    model = Repo.get_by!(ScenarioModel, %{name: scenario.name})
    model = Repo.preload model, :rules
    model.rules
  end

  defp stop_byid(child_id) do
    case Supervisor.terminate_child(__MODULE__, child_id) do
      :ok -> Supervisor.delete_child(__MODULE__, child_id)
      err -> err
    end
  end

  def stop(scenario = %Scenario{}) do
    child_id = get_child_name(scenario)
    stop_byid(child_id)
  end
  
  def stop(scenarios) when is_list(scenarios) do
    Enum.each(scenarios, fn(scenario) -> stop(scenario) end)
    :ok
  end

  def stopall do
    Supervisor.which_children(__MODULE__)
    |> Enum.each(
      &(case &1 do
          {child_id, _child, _type, [DtCore.Scenario]} -> stop_byid(child_id)
          _v -> nil
        end
      ))
    :ok
  end

  def running do
    status = Supervisor.count_children(__MODULE__)
    status.specs - 1
  end

  def get_child_name(scenario = %Scenario{name: nil}) do
    raise ArgumentError, message: "nil name not allowed"
  end

  def get_child_name(scenario = %Scenario{}) do
    to_string(__MODULE__)  <> "::scenario_server_for::" <> scenario.name
    |> String.to_atom
  end

  # 
  # Callbacks
  #
  def init(_) do
    Logger.info("Starting Scenario Supervisor")
    children = [worker(ScenarioLoader, [])]
    supervise(children, strategy: :one_for_one)
  end

end
