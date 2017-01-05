defmodule DtWeb.TokenServerTest do
  use ExUnit.Case

  alias DtWeb.TokenServer

  test "inserts a token" do
    {:ok, _pid} = TokenServer.start_link(:a)
    {:ok, "token"} = TokenServer.put("token", :a)
  end

  test "same token is inserted once" do
    {:ok, _pid} = TokenServer.start_link(:b)
    {:ok, "token"} = TokenServer.put("token", :b)
    {:ok, "token"} = TokenServer.put("token", :b)
    tokens = TokenServer.all(:b)

    assert Enum.count(tokens) == 1
    assert Enum.at(tokens, 0) == "token"
  end

  test "get a token" do
    {:ok, _pid} = TokenServer.start_link(:c)
    TokenServer.put("token", :c)
    {:ok, "token"} = TokenServer.get("token", :c)
  end

  test "get a not existent token" do
    {:ok, _pid} = TokenServer.start_link(:d)
    {:error, :not_found} = TokenServer.get("token", :d)
  end

  test "deletes a token" do
    {:ok, _pid} = TokenServer.start_link(:e)
    TokenServer.put("token", :e)
    :ok = TokenServer.delete("token", :e)

    tokens = TokenServer.all(:e)

    assert Enum.count(tokens) == 0
  end
end
