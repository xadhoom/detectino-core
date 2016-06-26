defmodule DtWeb.SessionController do
  use DtWeb.Web, :controller

  alias DtWeb.User
  alias DtWeb.UserQuery
  alias DtWeb.StatusCodes

  def unauthenticated(conn, _params) do
    send_resp(conn, 401, StatusCodes.status_code(401))
  end

  def create(conn, params = %{}) do
    user = Repo.one(UserQuery.by_username(params["user"]["username"] || ""))
    if user do
      changeset = User.login_changeset(user, params["user"])
      if changeset.valid? do
        claims = Guardian.Claims.app_claims
        |> Map.put("role", user.role)
        |> Guardian.Claims.ttl({1, :hours})
        {:ok, jwt, full_claims} = Guardian.encode_and_sign(user, :token, claims)
        conn
        |> render(:logged_in, token: jwt)
      else
        send_resp(conn, 401, StatusCodes.status_code(401))
      end
    else
      send_resp(conn, 401, StatusCodes.status_code(401))
    end
  end

end
