defmodule DtCtx.UserTest do
  use DtCtx.DataCase

  alias DtCtx.Accounts.User

  @sample_user %User{id: 1, encrypted_password: "$2b$12$YVI.NrsX3O2z5SwD4hOPt.J9yU8xlt3ns2dcMqSm3oYGVygMZQmb6",
    username: "some content", name: "some content", password: "password", pin: "1234", role: "admin"}
  @invalid_attrs %{}

  test "login changeset with valid attributes" do
    changeset = User.login_changeset(%User{encrypted_password: "$2b$12$YVI.NrsX3O2z5SwD4hOPt.J9yU8xlt3ns2dcMqSm3oYGVygMZQmb6"},
      %{username: "some content",
        name: "some content",
        password: "password"})
    assert changeset.valid?
  end

  test "update changeset with valid attributes" do
    changeset = User.update_changeset(@sample_user,
      %{id: "1",
        username: "some content",
        name: "some content",
        pin: "1234",
        role: "admin",
        password: "another_password"})
    assert changeset.valid?
  end

  test "update changeset with no password change" do
    changeset = User.update_changeset(@sample_user,
      %{id: "1",
        username: "another_username",
        name: "some content",
        pin: "1234",
        role: "admin"})
    assert changeset.valid?
    {:ok, username} = Ecto.Changeset.fetch_change(changeset, :username)
    assert username == "another_username"
  end

  test "login changeset with invalid attributes" do
    changeset = User.login_changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

end
