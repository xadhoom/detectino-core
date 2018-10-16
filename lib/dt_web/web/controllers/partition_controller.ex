defmodule DtWeb.PartitionController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, repo: DtCtx.Repo, model: DtCtx.Monitoring.Partition, orderby: [:name]

  alias DtWeb.StatusCodes
  alias DtCtx.Monitoring.Partition
  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias DtWeb.Plugs.CheckPermissions
  alias DtCore.Monitor.Partition, as: PartitionProcess
  alias Guardian.Plug.EnsureAuthenticated

  plug(EnsureAuthenticated, handler: SessionController)
  plug(CoreReloader, nil when not (action in [:index, :show, :arm, :disarm]))
  plug(CheckPermissions, [roles: [:admin]] when not (action in [:index, :arm, :disarm]))
  plug(PinAuthorize)

  def disarm(conn, %{"id" => id}) do
    case Repo.get(Partition, id) do
      nil ->
        send_resp(conn, 404, StatusCodes.status_code(404))

      part ->
        part
        |> Partition.disarm()
        |> Repo.update!()
        |> PartitionProcess.disarm(PinAuthorize.username(conn))

        send_resp(conn, 204, StatusCodes.status_code(204))
    end
  end

  def arm(conn, params) do
    case do_arm(params, conn) do
      :ok -> send_resp(conn, 204, StatusCodes.status_code(204))
      {:error, :bad_request} -> send_resp(conn, 400, StatusCodes.status_code(400))
      {:error, :tripped} -> send_resp(conn, 555, StatusCodes.status_code(555))
      {:error, :not_found} -> send_resp(conn, 404, StatusCodes.status_code(404))
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
      end)

    result
  end
end
