defmodule DtWeb.EventController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtWeb.Repo, model: DtWeb.Event]

  alias DtWeb.SessionController
  alias DtWeb.Event
  alias DtWeb.StatusCodes
  alias DtWeb.CtrlHelpers.Crud

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]

  def index(conn, params) do
    case Crud.all(conn, params, Repo, Event, [:outputs]) do
      {:ok, conn, items} ->
        render(conn, items: items)
      {:error, conn, code} ->
        send_resp(conn, code, StatusCodes.status_code(code))
    end
  end
end
