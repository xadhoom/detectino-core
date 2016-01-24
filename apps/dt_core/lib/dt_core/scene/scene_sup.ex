defmodule DtCore.SceneSup do
  use Supervisor

  alias DtCore.Scene
  alias DtCore.SceneLoader

  #
  # Client APIs
  #
  def start_link do
    Supervisor.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def start(scene = %Scene{}) do
    child = worker(Scene, [], id: scene.name, restart: :transient)
    Supervisor.start_child(__MODULE__, child)
  end
  
  def start(scenes) when is_list(scenes) do
    Enum.each(scenes, fn(scene) -> start(scene) end)
  end

  def stop(scene = %Scene{}) do
    child_id = scene.name
    case Supervisor.terminate_child(__MODULE__, child_id) do
      :ok -> Supervisor.delete_child(__MODULE__, child_id)
      err -> err
    end
  end
  
  def stop(scenes) when is_list(scenes) do
    Enum.each(scenes, fn(scene) -> stop(scene) end)
    :ok
  end

  def running do
    status = Supervisor.count_children(__MODULE__)
    status.specs - 1
  end

  # 
  # Callbacks
  #
  def init(_) do
    children = [worker(SceneLoader, [])]
    supervise(children, strategy: :one_for_one)
  end

end
