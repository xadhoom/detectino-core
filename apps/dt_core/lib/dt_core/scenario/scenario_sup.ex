defmodule DtCore.ScenarioSup do
  use Supervisor

  alias DtCore.Scenario
  alias DtCore.ScenarioLoader

  #
  # Client APIs
  #
  def start_link do
    Supervisor.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def start(scenario = %Scenario{}) do
    child = worker(Scenario, [], id: get_child_name(scenario), restart: :transient)
    Supervisor.start_child(__MODULE__, child)
  end
  
  def start(scenarios) when is_list(scenarios) do
    Enum.each(scenarios, fn(scenario) -> start(scenario) end)
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
  end

  # 
  # Callbacks
  #
  def init(_) do
    children = [worker(ScenarioLoader, [])]
    supervise(children, strategy: :one_for_one)
  end

end
