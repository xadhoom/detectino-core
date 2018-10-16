defmodule DtWeb.EventLogController do
  @moduledoc """
  Controller for manipulating event logs.
  """
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, repo: DtCtx.Repo, model: DtCtx.Outputs.EventLog

  alias DtWeb.SessionController
  alias DtCtx.Outputs.EventLog
  alias DtWeb.StatusCodes
  alias DtWeb.Plugs.PinAuthorize
  alias Guardian.Plug.EnsureAuthenticated

  require Logger

  plug(EnsureAuthenticated, handler: SessionController)
  plug(PinAuthorize)

  def create(conn, _params) do
    send_resp(conn, 501, StatusCodes.status_code(501))
  end

  def ackall(conn, _params) do
    op =
      Repo.transaction(fn ->
        ackall_txn()
      end)

    code =
      case op do
        {:ok, _} ->
          204

        {:error, any} ->
          Logger.error("Cannot ack all events, cause #{inspect(any)}")
          500
      end

    send_resp(conn, code, StatusCodes.status_code(code))
  end

  def ackall_txn do
    q =
      from(e in EventLog,
        where: [acked: false]
      )

    q
    |> Repo.all()
    |> Enum.each(fn ev ->
      case do_ack(ev) do
        204 -> nil
        # mmmh must be sure of the txn
        _ -> Repo.rollback(:cannot_ack_all_logs)
      end
    end)
  end

  def ack(conn, %{"id" => id}) do
    code =
      case Repo.get(EventLog, id) do
        nil -> 404
        eventlog -> do_ack(eventlog)
      end

    send_resp(conn, code, StatusCodes.status_code(code))
  end

  defp do_ack(eventlog) do
    case eventlog do
      nil ->
        401

      x ->
        {ret, _} = x |> EventLog.ack() |> Repo.update()

        case ret do
          :ok -> 204
          _ -> 500
        end
    end
  end
end
