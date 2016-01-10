defmodule DtWeb.SessionApiController do
  use DtWeb.Web, :controller

  alias DtWeb.User
  alias DtWeb.UserQuery
  alias DtWeb.StatusCodes

  def unauthenticated(conn, params) do
    send_resp(conn, 403, StatusCodes.status_code(403))
  end

  def create(conn, params = %{}) do
    user = Repo.one(UserQuery.by_email(params["user"]["email"] || ""))
    if user do
      changeset = User.login_changeset(user, params["user"])
      if changeset.valid? do
        { :ok, jwt, full_claims } = Guardian.encode_and_sign(user, :api)
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
