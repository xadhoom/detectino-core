defmodule DtCore.SceneSupTest do
  use DtCore.EctoCase

  alias DtCore.Scene
  alias DtCore.SceneSup

  setup do
    SceneSup.start_link
    :ok
  end

  test "Empty scene list starts zero workers" do
    scenes = []
    SceneSup.start(scenes)
    assert SceneSup.running == 0
  end

  test "Scene list with same name starts one worker" do
    scenes = [
      %Scene{},
      %Scene{}
      ]
    SceneSup.start(scenes)
    assert SceneSup.running == 1
  end

  test "Scene list starts workers" do
    scenes = [
      %Scene{name: "s1"},
      %Scene{name: "s2"}
      ]
    SceneSup.start(scenes)
    assert SceneSup.running == 2
  end

  test "Scene list starts and stops workers" do
    scenes = [
      %Scene{name: "s1"},
      %Scene{name: "s2"}
      ]
    SceneSup.start(scenes)
    assert SceneSup.running == 2

    SceneSup.stop(scenes)
    assert SceneSup.running == 0
  end

  test "Scene list starts many and stops one worker" do
    s1 = %Scene{name: "s1"}
    s2 = %Scene{name: "s2"}
    scenes = [s1, s2]
    SceneSup.start(scenes)
    assert SceneSup.running == 2

    assert SceneSup.stop(s1) == :ok
    assert SceneSup.running == 1
  end

  test "Scene list start one worker" do
    s1 = %Scene{name: "s1"}
    SceneSup.start(s1)
    assert SceneSup.running == 1
  end

  test "Stop invalid worker" do
    s1 = %Scene{name: "s1"}
    assert {:error, :not_found} = SceneSup.stop(s1)
    assert SceneSup.running == 0
  end

  test "Stop invalid workers" do
    scenes = [
      %Scene{name: "s1"},
      %Scene{name: "s2"}
      ]
    assert :ok = SceneSup.stop(scenes)
    assert SceneSup.running == 0
  end

end
