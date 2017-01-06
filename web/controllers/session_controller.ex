defmodule DtWeb.SessionController do
  use DtWeb.Web, :controller

  alias DtWeb.User
  alias DtWeb.UserQuery
  alias DtWeb.TokenServer
  alias DtWeb.StatusCodes
  alias DtWeb.SessionController
  alias DtWeb.Plugs.CheckPermissions
  alias Guardian.Claims
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController] when action in [
    :refresh, :invalidate]

  plug CheckPermissions, [roles: [:admin]] when action in [:invalidate]

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
      _user ->
        {:ok, jwt, _claims} = Guardian.refresh!(token)
        conn |> render(:logged_in, token: jwt)
    end
  end

  def invalidate(conn, %{"id" => id}) do
    id = id |> String.to_integer()
    get_tokens_for_id(id)
    |> Enum.each(fn(token) ->
      TokenServer.delete(token)
    end)

    send_resp(conn, 204, StatusCodes.status_code(204))
  end

  defp get_tokens_for_id(id) do
    TokenServer.all()
    |> Enum.filter(fn(token) ->
      claims = Guardian.peek_claims(token)
      id == claims["dt_user_id"]
    end)
  end

end
