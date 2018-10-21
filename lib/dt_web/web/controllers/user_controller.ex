defmodule DtWeb.UserController do
  @moduledoc false
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, repo: DtCtx.Repo, model: DtCtx.Accounts.User

  alias DtWeb.SessionController
  alias DtWeb.Plugs.PinAuthorize
  alias DtWeb.Plugs.CheckPermissions
  alias DtCtx.Accounts.User
  alias Guardian.Plug.EnsureAuthenticated
  alias Plug.Conn.Status

  plug(EnsureAuthenticated, handler: SessionController)
  plug(CheckPermissions, [roles: [:admin]] when action not in [:check_pin])
  plug(PinAuthorize when action not in [:check_pin])

  def delete(conn, %{"id" => "1"}) do
    send_resp(conn, 403, Status.reason_phrase(403))
  end

  def delete(conn, params) do
    super(conn, params)
  end

  def check_pin(conn, %{"pin" => pin}) do
    q = from(u in User, where: u.pin == ^pin, select: u.pin_expire)

    case Repo.one(q) do
      nil ->
        send_resp(conn, 404, Status.reason_phrase(404))

      v ->
        render(conn, :check_pin, expire: v)
    end
  end

  def check_pin(conn, _) do
    send_resp(conn, 400, Status.reason_phrase(400))
  end
end
