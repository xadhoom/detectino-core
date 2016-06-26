defmodule DtCore.Scenario do
  use GenServer

  require Logger
  alias DtCore.Rule
  alias DtCore.Event
  alias DtCore.Handler
  alias DtCore.Action

  defstruct name: nil,
    model: nil

  #
  # Client APIs
  #
  def start_link(rules, server_name) when is_list(rules) and is_atom(server_name) do
    Logger.debug("Starting Scenario Server with #{inspect rules} rules")
    GenServer.start_link(__MODULE__, {rules, server_name}, name: server_name)
  end

  def get_rules(server_name) do
    GenServer.call server_name, {:get_rules}
  end

  def last_event(server_name) do
    GenServer.call server_name, {:last_event}
  end

  def last_action(server_name) do
    GenServer.call server_name, {:last_action}
  end

  def get_processor(server_name) do
    GenServer.call server_name, {:get_processor}
  end

  #
  # GenServer callbacks
  #
  def init({rules, name}) do
    Logger.info "Starting Scenario Server " <> to_string(name)
    {:ok, _myself} = Handler.start_listening
    {:ok, pid} = Action.start_link
    {:ok,
      %{
        parser: Rule.load,
        rules: rules,
        processor: pid,
        last_event: nil
      }
    }
  end

  def handle_call({:get_rules}, from, state) do
    {:reply, state.rules, state}
  end

  def handle_call({:last_event}, _from, state) do
    {:reply, state.last_event, state}
  end

  def handle_call({:get_processor}, _from, state) do
    {:reply, state.processor, state}
  end

  def handle_call({:last_action}, _from, state) do
    last_action = Action.last state.processor
    {:reply, last_action, state}
  end

  def handle_info({:event, event}, state) do
    res = process_rules(event, state)
    Action.dispatch state.processor, res

    {:noreply, %{state | last_event: event}}
  end

  def terminate(:normal, state) do
    IO.inspect "stopping action server"
    Action.stop state.processor
  end

  def terminate(:shutdown, state) do
    IO.inspect "stopping action server"
    Process.exit state.processor, :normal
  end

  def process_rules(event, state) do
    Enum.reduce_while(state.rules, [], fn rule, acc ->
      acc = case Rule.apply state.parser, event, rule.expression do
        nil -> acc  
        result -> List.insert_at acc, -1, result
      end
      case rule.continue do
        :true -> {:cont, acc}
        :false -> {:halt, acc}
        _ -> {:halt, acc}
      end
    end)
  end

end
