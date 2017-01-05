defmodule DtWeb.SessionController do
  use DtWeb.Web, :controller

  alias DtWeb.User
  alias DtWeb.UserQuery
  alias DtWeb.TokenServer
  alias DtWeb.StatusCodes
  alias DtWeb.SessionController
  alias Guardian.Claims
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController] when action in [:refresh]

  def unauthenticated(conn, _params) do
    token = conn
    |> get_req_header("authorization")
    |> Enum.at(0)

    case token do
      nil -> nil
      v -> TokenServer.expire({:token, v})
    end

    send_resp(conn, 401, StatusCodes.status_code(401))
  end

  def create(conn, params = %{}) do
    user = Repo.one(UserQuery.by_username(params["user"]["username"] || ""))
    if user do
      changeset = User.login_changeset(user, params["user"])
      if changeset.valid? do
        reset_reauth_flag(user)
        claims = Claims.app_claims
        |> Map.put("dt_role", user.role)
        |> Map.put("dt_user_id", user.id)
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

  def refresh(conn, _params = %{}) do
    token = conn
    |> get_req_header("authorization")
    |> Enum.at(0)

    claims = Guardian.decode_and_verify!(token)
    case Repo.get(User, claims["dt_user_id"]) do
      nil ->
        send_resp(conn, 404, StatusCodes.status_code(404))
      user ->
        validate_and_refresh(conn, token, user)
    end
  end

  defp validate_and_refresh(conn, token, user) do
    case user.re_auth do
      true ->
        send_resp(conn, 403, StatusCodes.status_code(403))
      _ ->
        {:ok, jwt, _claims} = Guardian.refresh!(token)
        conn |> render(:logged_in, token: jwt)
    end
  end

  defp reset_reauth_flag(user) do
    case user.re_auth do
      true ->
        User.update_changeset(user, %{id: user.id, re_auth: false})
        |> Repo.update!
      false ->
        user
    end
  end

end
