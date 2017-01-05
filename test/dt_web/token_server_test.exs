defmodule DtWeb.TokenServerTest do
  use ExUnit.Case

  alias DtWeb.TokenServer

  test "inserts a token" do
    {:ok, _pid} = TokenServer.start_link(:a)
    {:ok, "token"} = TokenServer.put("token")
  end

  test "same token is inserted once" do
    {:ok, _pid} = TokenServer.start_link(:b)
    {:ok, "token"} = TokenServer.put("token")
    {:ok, "token"} = TokenServer.put("token")
    tokens = TokenServer.all()

    assert Enum.count(tokens) == 1
    assert Enum.at(tokens, 0) == "token"
  end

  test "get a token" do
    {:ok, _pid} = TokenServer.start_link(:c)
    TokenServer.put("token")
    {:ok, "token"} = TokenServer.get("token")
  end

  test "get a not existen token" do
    {:ok, _pid} = TokenServer.start_link(:d)
    {:error, :not_found} = TokenServer.get("token")
  end

  test "deletes a token" do
    {:ok, _pid} = TokenServer.start_link(:e)
    TokenServer.put("token")
    :ok = TokenServer.delete("token")

    tokens = TokenServer.all()

    assert Enum.count(tokens) == 0
  end
end
