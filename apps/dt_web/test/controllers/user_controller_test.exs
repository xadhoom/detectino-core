defmodule DtWeb.UserControllerTest do
  use DtWeb.ConnCase

  alias DtWeb.User
  @valid_attrs %{email: "some content", encrypted_password: "some content", name: "some content", password: "some content"}
  @invalid_attrs %{}

  setup do
    conn = conn()
    {:ok, conn: conn}
  end

end
