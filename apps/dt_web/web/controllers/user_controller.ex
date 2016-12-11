defmodule DtWeb.UserController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtWeb.Repo, model: DtWeb.User]

  alias DtWeb.SessionController
  alias DtWeb.StatusCodes
  alias DtWeb.Plugs.PinAuthorize

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]
  plug PinAuthorize

  def delete(conn, %{"id" => "1"}) do
    send_resp(conn, 403, StatusCodes.status_code(403))
  end

  def delete(conn, params) do
    super(conn, params)
  end

end
