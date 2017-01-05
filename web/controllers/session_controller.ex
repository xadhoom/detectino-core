defmodule DtWeb.SessionController do
  use DtWeb.Web, :controller

  alias DtWeb.User
  alias DtWeb.UserQuery
  alias DtWeb.StatusCodes
  alias DtWeb.SessionController
  alias Guardian.Claims
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController] when action in [:refresh]

  def unauthenticated(conn, _params) do
    send_resp(conn, 401, StatusCodes.status_code(401))
  end

  def create(conn, params = %{}) do
    user = Repo.one(UserQuery.by_username(params["user"]["username"] || ""))
    if user do
      changeset = User.login_changeset(user, params["user"])
      if changeset.valid? do
        claims = Claims.app_claims
        |> Map.put("role", user.role)
        |> Claims.ttl({1, :hours})
        {:ok, jwt, _full_claims} = user
        |> Guardian.encode_and_sign(:token, claims)
        conn
        |> render(:logged_in, token: jwt)
      else
        send_resp(conn, 401, StatusCodes.status_code(401))
      end
    else
      send_resp(conn, 401, StatusCodes.status_code(401))
    end
  end

  def refresh(conn, params = %{}) do
    {:ok, jwt, claims} = conn
    |> get_req_header("authorization")
    |> Enum.at(0)
    |> Guardian.refresh!

    conn
    |> render(:logged_in, token: jwt)
  end

end
