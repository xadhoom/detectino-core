defmodule DtLib.Test.Delayer do
  use ExUnit.Case, async: true

  alias DtLib.Delayer

  test "can start link" do
    {:ok, pid} = Delayer.start_link()
    assert is_pid(pid)
  end

  test "put some terms into it" do
    refs = []
    {:ok, pid} = Delayer.start_link()

    {:ok, ref} = Delayer.put(pid, :atom, 100)
    assert is_reference(ref)
    refs = [ref | refs]

    {:ok, ref} = Delayer.put(pid, "a string", 1)
    assert is_reference(ref)
    refs = [ref | refs]

    {:ok, ref} = Delayer.put(pid, [:a, :list], 10)
    assert is_reference(ref)
    refs = [ref | refs]

    {:ok, ref} = Delayer.put(pid, %{im: "a map"}, 42)
    assert is_reference(ref)
    refs = [ref | refs]

    {:ok, ref} = Delayer.put(pid, {:tuple, :for, "you"}, 77)
    assert is_reference(ref)
    refs = [ref | refs]

    refs = Enum.uniq(refs)
    assert Enum.count(refs) == 5
  end

  test "cannot add with delay 0" do
    assert :error == Delayer.put(:any, :any, 0)
  end

  test "warp the time" do
    {:ok, pid} = Delayer.start_link()

    {:ok, _ref} = Delayer.put(pid, :atom, 1000)
    :warped = Delayer.warp(pid, 1000)
    assert_received :atom
  end

  test "normal time (longer test...)" do
    {:ok, pid} = Delayer.start_link()

    {:ok, _ref} = Delayer.put(pid, :atom, 1000)
    assert_receive :atom, 2000
  end

  test "different terms have different delays" do
    {:ok, pid} = Delayer.start_link()

    {:ok, _ref} = Delayer.put(pid, :a, 1000)
    {:ok, _ref} = Delayer.put(pid, :b, 2000)
    {:ok, _ref} = Delayer.put(pid, :c, 3000)
    {:ok, _ref} = Delayer.put(pid, :d, 4000)

    # first check
    :warped = Delayer.warp(pid, 1000)
    assert_received :a
    refute_received :b
    refute_received :c
    refute_received :d

    # second check
    :warped = Delayer.warp(pid, 2000)
    assert_received :b
    refute_received :c
    refute_received :d

    # 3rd check
    :warped = Delayer.warp(pid, 3000)
    assert_received :c
    refute_received :d

    # final check
    :warped = Delayer.warp(pid, 4000)
    assert_received :d
  end

  test "one warp to rule them all" do
    {:ok, pid} = Delayer.start_link()

    {:ok, _ref} = Delayer.put(pid, :a, 1000)
    {:ok, _ref} = Delayer.put(pid, :b, 2000)
    {:ok, _ref} = Delayer.put(pid, :c, 3000)
    {:ok, _ref} = Delayer.put(pid, :d, 4000)

    :warped = Delayer.warp(pid, 5000)
    assert_received :a
    assert_received :b
    assert_received :c
    assert_received :d
  end

  test "can start many delayers" do
    {:ok, pid} = Delayer.start_link()
    assert is_pid(pid)

    {:ok, pid} = Delayer.start_link()
    assert is_pid(pid)

    {:ok, pid} = Delayer.start_link()
    assert is_pid(pid)
  end

end
