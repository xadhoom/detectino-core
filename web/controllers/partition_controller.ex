defmodule DtWeb.PartitionController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtWeb.Repo, model: DtWeb.Partition]

  alias DtWeb.StatusCodes
  alias DtWeb.Partition
  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]
  plug CoreReloader, nil when not action in [:index, :show]
  plug PinAuthorize

  def disarm(conn, %{"id" => id}) do
    case Repo.get(Partition, id) do
      nil ->
        send_resp(conn, 404, StatusCodes.status_code(404))
      part ->
        part |> Partition.disarm |> Repo.update!
        send_resp(conn, 204, StatusCodes.status_code(204))
    end
  end

  def arm(conn, %{"id" => id, "mode" => mode}) do
    case Repo.get(Partition, id) do
      nil ->
        send_resp(conn, 404, StatusCodes.status_code(404))
      part ->
        cset = part |> Partition.arm(mode)
        case cset.valid? do
          true ->
            cset |> Repo.update!
            send_resp(conn, 204, StatusCodes.status_code(204))
          false ->
            send_resp(conn, 400, StatusCodes.status_code(400))
        end
    end
  end

end
