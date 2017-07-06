defmodule DtWeb.CtrlHelpers.CrudTest do
  use DtWeb.ConnCase

  alias DtWeb.Repo
  alias DtCtx.Accounts.User
  alias DtWeb.CtrlHelpers.Crud

  @user1 %User{name: "a", username: "a"}
  @user2 %User{name: "b", username: "b"}
  @user3 %User{name: "c", username: "c"}

  test "Get all" do
    conn = Phoenix.ConnTest.build_conn
    {:ok, conn, _items} = Crud.all(conn, %{}, {Repo, User, nil})
    total_h = get_resp_header(conn, "x-total-count")

    assert total_h == ["1"]
  end

  test "Get all with filter" do
    Repo.insert!(@user3)
    Repo.insert!(@user2)
    Repo.insert!(@user1)

    conn = Phoenix.ConnTest.build_conn

    filt = %{"name" => "b"}
    {:ok, conn, items} = Crud.all(conn, filt, {Repo, User, nil})

    total_h = get_resp_header(conn, "x-total-count")
    assert total_h == ["1"]

    first = Enum.at(items, 0)
    assert first.name == "b"
  end

  test "Get all with ordering" do
    Repo.insert!(@user3)
    Repo.insert!(@user2)
    Repo.insert!(@user1)

    conn = Phoenix.ConnTest.build_conn

    {:ok, _conn, items} = Crud.all(conn, %{}, {Repo, User, nil})
    first = Enum.at(items, 0)
    assert first.name == "admin"

    {:ok, _conn, items} = Crud.all(conn, %{}, {Repo, User, [:name]})
    first = Enum.at(items, 0)
    assert first.name == "a"
  end

  test "link header" do
    conn = Phoenix.ConnTest.build_conn
    Crud.links(conn, 2, 5, 26)
    |> ExLinkHeader.parse!
  end

  test "pagination contains all users" do
    Repo.insert!(@user1)
    Repo.insert!(@user2)
    Repo.insert!(@user3)

    conn = Phoenix.ConnTest.build_conn
    params = %{"per_page" => "10"}
    {:ok, conn, items} = Crud.all(conn, params, {Repo, User, nil})
    total_h = get_resp_header(conn, "x-total-count")

    assert total_h == ["4"]
    assert Enum.count(items) == 4

    links = get_resp_header(conn, "link")
    |> Enum.at(0)
    |> ExLinkHeader.parse!

    assert links.first.params == %{page: "1", per_page: "10"}
    assert links.next == nil
    assert links.last.params == %{page: "1", per_page: "10"}

  end

  test "pagination does not contains all users" do
    Repo.insert!(@user1)
    Repo.insert!(@user2)
    Repo.insert!(@user3)

    conn = Phoenix.ConnTest.build_conn
    params = %{"per_page" => "2"}
    {:ok, conn, items} = Crud.all(conn, params, {Repo, User, nil})
    total_h = get_resp_header(conn, "x-total-count")

    assert total_h == ["4"]
    assert Enum.count(items) == 2

    links = get_resp_header(conn, "link")
    |> Enum.at(0)
    |> ExLinkHeader.parse!

    assert links.first.params == %{page: "1", per_page: "2"}
    assert links.next.params == %{page: "2", per_page: "2"}
    assert links.last.params == %{page: "2", per_page: "2"}

  end

end

