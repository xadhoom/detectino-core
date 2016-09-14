defmodule DtWeb.UserController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros

  alias DtWeb.User
  alias DtWeb.SessionController
  alias DtWeb.StatusCodes

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]

  @repo Repo
  @model User

  def delete(conn, %{"id" => "1"}) do
    send_resp(conn, 403, StatusCodes.status_code(403))
  end

end
