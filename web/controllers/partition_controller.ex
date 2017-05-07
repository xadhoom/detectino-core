defmodule DtWeb.PartitionController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [
    repo: DtWeb.Repo, model: DtWeb.Partition, orderby: [:name]
  ]

  alias DtWeb.StatusCodes
  alias DtWeb.Partition
  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias DtCore.Sensor.Partition, as: PartitionProcess
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]
  plug CoreReloader, nil when not action in [:index, :show, :arm, :disarm]
  plug PinAuthorize

  def disarm(conn, %{"id" => id}) do
    case Repo.get(Partition, id) do
      nil ->
        send_resp(conn, 404, StatusCodes.status_code(404))
      part ->
        part
        |> Partition.disarm
        |> Repo.update!
        |> PartitionProcess.disarm("DISARM")
        send_resp(conn, 204, StatusCodes.status_code(204))
    end
  end

  def arm(conn, params) do
    case do_arm(params) do
      :ok -> send_resp(conn, 204, StatusCodes.status_code(204))
      {:error, :bad_request} -> send_resp(conn, 400, StatusCodes.status_code(400))
      {:error, :tripped} -> send_resp(conn, 403, StatusCodes.status_code(403))
      {:error, :not_found} -> send_resp(conn, 404, StatusCodes.status_code(404))
    end
  end

  defp do_arm(%{"id" => id, "mode" => mode}) do
    case Repo.get(Partition, id) do
      nil ->
        {:error, :not_found}
      part ->
        part |> Partition.arm(mode) |> arm_transaction(mode)
    end
  end

  defp arm_transaction(cset, mode) do
    Repo.transaction(fn ->
      case cset.valid? do
        true ->
          res = cset
          |> Repo.update!
          |> PartitionProcess.arm(mode)
          case res do
            :ok -> :ok
            {:error, :tripped} -> Repo.rollback(:tripped)
          end
        false ->
          {:error, :bad_request}
      end
    end)
  end

end
