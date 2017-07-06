defmodule DtCore.Output.Server do
  @moduledoc """
  Server responsible of starting/stopping outputs workers.
  """
  use GenServer
  import Supervisor.Spec
  require Logger

  alias DtCore.Output.OutputSup
  alias DtCore.Output.Worker
  alias DtWeb.Repo
  alias DtCtx.Outputs.Output, as: OutputModel
  alias DtWeb.ReloadRegistry

  @name :output_server

  #
  # Client APIs
  #
  def start_link(sup) do
    GenServer.start_link(__MODULE__, sup, [name: @name])
  end

  @doc """
  Reloads the server and workers.
  This stops workers, worker sup and reloads everything from DB
  """
  def reload do
    GenServer.call(@name, {:reload})
  end

  def outputs do
    GenServer.call(@name, {:outputs})
  end

  #
  # GenServer callbacks
  #
  def init(sup) do
    Logger.info fn -> "Supervisor #{inspect sup} starting Output Server" end
    send self(), :start
    {:ok, %{
      sup: sup,
      output_sup: nil
      }
    }
  end

  def handle_call({:reload}, _from, state) do
    {res, state} = do_reload(state)
    {:reply, res, state}
  end

  @doc false
  def handle_call({:outputs}, _from, state = %{output_sup: nil}) do
    {:reply, {:error, :reloading}, state}
  end

  @doc false
  def handle_call({:outputs}, _from, state) do
    res = Supervisor.count_children(state.output_sup)
    {:reply, {:ok, res.active}, state}
  end

  @doc """
  Starts the server by spawning the workers sup and all
  outputs from the DB
  """
  def handle_info(:start, state) do
    case Supervisor.start_child(state.sup, supervisor(OutputSup, [],
                                restart: :temporary)) do
      {:ok, pid} ->
        Process.monitor pid
        state = %{state | output_sup: pid}
        start_outputs(state)
        Registry.register(ReloadRegistry.registry, ReloadRegistry.key, [])
        {:noreply, state}
      {:error, err} ->
        Logger.error fn -> "Error starting Outputs Sup #{inspect err}" end
        {:stop, err, state}
    end
  end

  @doc """
  Handle reload request message
  """
  def handle_info({:reload}, state) do
    {:ok, state} = do_reload(state)
    {:noreply, state}
  end

  @doc """
  Handle :normal :DOWN messages from our worker sup
  """
  def handle_info({:DOWN, _ref, _process, _pid, :normal}, state) do
    Logger.info "Outputs supervisor down, normal"
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, _process, _pid, :shutdown}, state) do
    Logger.info "Outputs supervisor down, shutdown"
    {:noreply, state}
  end

  @doc """
  Handle not :normal :DOWN messages from our worker sup
  and restart everything
  """
  def handle_info({:DOWN, _ref, _process, pid, reason}, state) do
    sup = state.output_sup
    case pid do
      ^sup ->
        Logger.error fn ->
          "Outputs Sup died with reason #{inspect reason}, I quit!"
        end
        {:stop, reason, state}
      any ->
        Logger.info fn -> "Got :DOWN message from #{inspect any} " <>
          "but is not my outputs worker supervisor, ignoring...." end
        {:noreply, state}
    end
  end

  defp do_reload(state) do
    :ok = Supervisor.stop(state.output_sup, :normal)
    send self(), :start
    {:ok, %{state | output_sup: nil}}
  end

  defp start_outputs(state) do
    OutputModel
    |> Repo.all
    |> Repo.preload(:events)
    |> Enum.each(fn(output) ->
      case Enum.empty?(output.events) do
        false -> start_output(output, state)
        _ -> nil
      end
    end)
  end

  defp start_output(output, state) do
    id = output.name
    case Supervisor.start_child(state.output_sup,
          worker(Worker, [{output}],
            restart: :transient, id: id)) do
      {:ok, pid} ->
        Logger.info fn -> "Started output worker with pid #{inspect pid}" end
      {:error, err} ->
        Logger.error fn -> "Cannot start output worker: " <>
          "#{inspect err} #{inspect output}" end
    end
  end

end
