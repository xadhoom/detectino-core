defmodule DtWeb.PartitionController do
  @moduledoc false
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, repo: DtCtx.Repo, model: DtCtx.Monitoring.Partition, orderby: [:name]

  alias DtCore.Monitor.Partition, as: PartitionProcess
  alias DtCtx.Monitoring.Partition
  alias DtWeb.Plugs.CheckPermissions
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias DtWeb.SessionController
  alias Guardian.Plug.EnsureAuthenticated
  alias Plug.Conn.Status

  plug(EnsureAuthenticated, handler: SessionController)
  plug(CoreReloader, nil when action not in [:index, :show, :arm, :disarm])
  plug(CheckPermissions, [roles: [:admin]] when action not in [:index, :arm, :disarm])
  plug(PinAuthorize)

  def disarm(conn, %{"id" => id}) do
    case Repo.get(Partition, id) do
      nil ->
        send_resp(conn, 404, Status.reason_phrase(404))

      part ->
        part
        |> Partition.disarm()
        |> Repo.update!()
        |> PartitionProcess.disarm(PinAuthorize.username(conn))

        send_resp(conn, 204, Status.reason_phrase(204))
    end
  end

  def arm(conn, params) do
    case do_arm(params, conn) do
      :ok -> send_resp(conn, 204, Status.reason_phrase(204))
      {:error, :bad_request} -> send_resp(conn, 400, Status.reason_phrase(400))
      {:error, :tripped} -> send_resp(conn, 555, Status.reason_phrase(555))
      {:error, :not_found} -> send_resp(conn, 404, Status.reason_phrase(404))
    end
  end

  defp do_arm(%{"id" => id, "mode" => mode}, conn) do
    amode = Partition.arm_mode_str_to_atom(mode)

    if amode == :error do
      {:error, :bad_request}
    else
      case Repo.get(Partition, id) do
        nil ->
          {:error, :not_found}

        part ->
          part |> Partition.arm(mode) |> arm_transaction(amode, conn)
      end
    end
  end

  defp arm_transaction(cset, mode, conn) do
    {_, result} =
      Repo.transaction(fn ->
        arm_transaction_txn(cset, mode, conn)
      end)

    result
  end

  defp arm_transaction_txn(cset, mode, conn) do
    case cset.valid? do
      true ->
        res =
          cset
          |> Repo.update!()
          |> PartitionProcess.arm(PinAuthorize.username(conn), mode)

        case res do
          :ok -> :ok
          {:error, :tripped} -> Repo.rollback({:error, :tripped})
        end

      false ->
        {:error, :bad_request}
    end
  end
end
