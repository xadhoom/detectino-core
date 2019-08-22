defmodule DtWeb.SessionController do
  @moduledoc false
  use DtWeb.Web, :controller

  alias DtCtx.Accounts.User
  alias DtCtx.Accounts.UserQuery
  alias DtWeb.Guardian, as: DtGuardian
  alias DtWeb.Plugs.CheckPermissions
  alias DtWeb.TokenServer
  alias Guardian.Plug.EnsureAuthenticated
  alias Plug.Conn.Status

  plug(EnsureAuthenticated when action in [:refresh, :invalidate])

  plug(CheckPermissions, [roles: [:admin]] when action in [:invalidate])

  def create(conn, params = %{}) do
    user = Repo.one(UserQuery.by_username(params["user"]["username"] || ""))

    if user do
      changeset = User.login_changeset(user, params["user"])

      if changeset.valid? do
        claims =
          %{}
          |> Map.put("dt_role", user.role)
          |> Map.put("dt_user_id", user.id)

        {:ok, jwt, _full_claims} =
          user
          |> DtGuardian.encode_and_sign(claims, ttl: {1, :hours})

        conn
        |> render(:logged_in, token: jwt)
      else
        send_resp(conn, 401, Status.reason_phrase(401))
      end
    else
      send_resp(conn, 401, Status.reason_phrase(401))
    end
  end

  def refresh(conn, _params = %{}) do
    token =
      conn
      |> get_req_header("authorization")
      |> Enum.at(0)

    {:ok, claims} = DtGuardian.decode_and_verify(token)

    case Repo.get(User, claims["dt_user_id"]) do
      nil ->
        send_resp(conn, 404, Status.reason_phrase(404))

      _user ->
        {:ok, {_old_token, _old_claims}, {jwt, _new_claims}} = DtGuardian.refresh(token)
        conn |> render(:logged_in, token: jwt)
    end
  end

  def invalidate(conn, %{"id" => id}) do
    id = id |> String.to_integer()

    id
    |> get_tokens_for_id()
    |> Enum.each(fn token ->
      TokenServer.delete(token)
    end)

    send_resp(conn, 204, Status.reason_phrase(204))
  end

  defp get_tokens_for_id(id) do
    TokenServer.all()
    |> Enum.filter(fn token ->
      %{claims: claims} = DtGuardian.peek(token)
      id == claims["dt_user_id"]
    end)
  end
end
