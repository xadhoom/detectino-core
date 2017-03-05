defmodule DtWeb.EventLogController do
  @moduledoc """
  Controller for manipulating event logs.
  """
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtWeb.Repo, model: DtWeb.EventLog]

  alias DtWeb.SessionController
  alias DtWeb.EventLog
  alias DtWeb.StatusCodes
  alias DtWeb.CtrlHelpers.Crud
  alias DtWeb.Plugs.PinAuthorize
  alias Guardian.Plug.EnsureAuthenticated

  require Logger

  plug EnsureAuthenticated, [handler: SessionController]
  plug PinAuthorize

  def index(conn, params) do
    order = [:inserted_at]
    case Crud.all(conn, params, {Repo, EventLog, order}) do
      {:ok, conn, items} ->
        render(conn, items: items)
      {:error, conn, code} ->
        send_resp(conn, code, StatusCodes.status_code(code))
    end
  end

  def create(conn, _params) do
    send_resp(conn, 501, StatusCodes.status_code(501))
  end

  def ack(conn, %{"id" => id}) do
    code = case Repo.get(EventLog, id) do
      nil -> 404
      eventlog -> do_ack(eventlog)
    end
    send_resp(conn, code, StatusCodes.status_code(code))
  end

  defp do_ack(eventlog) do
    case eventlog do
      nil -> 401
      x ->
        {ret, _} = EventLog.ack(x) |> Repo.update
        case ret do
          :ok -> 204
          _ -> 500
        end
    end
  end

end
