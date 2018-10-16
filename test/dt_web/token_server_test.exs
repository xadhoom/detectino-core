defmodule DtWeb.TokenServerTest do
  use ExUnit.Case

  alias DtWeb.TokenServer

  test "inserts a token" do
    {:ok, _pid} = TokenServer.start_link(:a)
    {:ok, "token"} = TokenServer.put("token", 3600, :a)
  end

  test "same token is inserted once" do
    {:ok, _pid} = TokenServer.start_link(:b)
    {:ok, "token"} = TokenServer.put("token", 3600, :b)
    {:ok, "token"} = TokenServer.put("token", 3600, :b)
    tokens = TokenServer.all(:b)

    assert Enum.count(tokens) == 1
    assert Enum.at(tokens, 0) == "token"
  end

  test "get a token" do
    {:ok, _pid} = TokenServer.start_link(:c)
    TokenServer.put("token", 3600, :c)
    {:ok, "token"} = TokenServer.get("token", :c)
  end

  test "get a not existent token" do
    {:ok, _pid} = TokenServer.start_link(:d)
    {:error, :not_found} = TokenServer.get("token", :d)
    assert :not_running == Etimer.stop_timer(:d, "token")
  end

  test "deletes a token" do
    {:ok, _pid} = TokenServer.start_link(:e)
    TokenServer.put("token", 3600, :e)
    :ok = TokenServer.delete("token", :e)

    tokens = TokenServer.all(:e)

    assert Enum.count(tokens) == 0
    assert :not_running == Etimer.stop_timer(:e, "token")
  end

  test "expires a token" do
    :meck.new(Etimer, [:passthrough])
    :meck.expect(Etimer, :start_timer, fn _, _, _, _ -> 42 end)

    {:ok, _pid} = TokenServer.start_link(:f)
    TokenServer.put("token", 3600, :f)
    tokens = TokenServer.all(:f)
    assert Enum.count(tokens) == 1

    assert :meck.called(Etimer, :start_timer, [
             :_,
             "token",
             3600 * 1000,
             {:_, :expire, [{:token, "token"}, :f]}
           ])

    :meck.unload(Etimer)

    TokenServer.expire({:token, "token"}, :f)

    tokens = TokenServer.all(:f)
    assert Enum.count(tokens) == 0
  end
end
