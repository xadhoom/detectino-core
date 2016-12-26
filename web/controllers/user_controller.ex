defmodule DtWeb.UserController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtWeb.Repo, model: DtWeb.User]

  alias DtWeb.SessionController
  alias DtWeb.StatusCodes
  alias DtWeb.Plugs.PinAuthorize
  alias DtWeb.User

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]
  plug PinAuthorize when not action in [:check_pin]

  def delete(conn, %{"id" => "1"}) do
    send_resp(conn, 403, StatusCodes.status_code(403))
  end

  def delete(conn, params) do
    super(conn, params)
  end

  def check_pin(conn, %{"pin" => pin}) do
    q = from u in User, where: u.pin == ^pin
    case Repo.one(q) do
      nil ->
        send_resp(conn, 404, StatusCodes.status_code(404))
      _ ->
        send_resp(conn, 200, StatusCodes.status_code(200))
    end
  end

  def check_pin(conn, _) do
    send_resp(conn, 400, StatusCodes.status_code(400))
  end

end