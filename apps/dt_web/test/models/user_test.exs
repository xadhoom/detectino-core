defmodule DtWeb.UserTest do
  use DtWeb.ModelCase

  alias DtWeb.User

  @invalid_attrs %{}

  test "login changeset with valid attributes" do
    changeset = User.login_changeset(%User{encrypted_password: "$2b$12$YVI.NrsX3O2z5SwD4hOPt.J9yU8xlt3ns2dcMqSm3oYGVygMZQmb6"}, 
      %{username: "some content", 
        name: "some content", 
        password: "password"})
    assert changeset.valid?
  end

  test "login changeset with invalid attributes" do
    changeset = User.login_changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

end
