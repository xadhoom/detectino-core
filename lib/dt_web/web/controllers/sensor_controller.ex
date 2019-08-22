defmodule DtWeb.SensorController do
  @moduledoc """
  Controller for manipulating sensors.

  XXX: check if some funs can be merged with event_controller
  """
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, repo: Repo, model: DtCtx.Monitoring.Sensor

  require Logger

  alias DtCtx.Monitoring.PartitionSensor
  alias DtCtx.Monitoring.Sensor
  alias DtWeb.Controllers.Helpers.Utils
  alias DtWeb.CtrlHelpers.Crud
  alias DtWeb.Plugs.CheckPermissions
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias DtWeb.SessionController
  alias Guardian.Plug.EnsureAuthenticated

  plug(EnsureAuthenticated, handler: SessionController)
  plug(CheckPermissions, roles: [:admin])
  plug(PinAuthorize)
  plug(CoreReloader, nil when action not in [:index, :show])

  def index(conn, params) do
    order = [:name]

    case Crud.all(conn, params, {Repo, Sensor, order}, [:partitions]) do
      {:ok, conn, items} ->
        render(conn, items: items)

      {:error, _conn, _code} ->
        nil
    end
  end

  def create(conn, params) do
    case Crud.create(conn, params, Sensor, Repo, :user_path, [:partitions]) do
      {:ok, conn, item} ->
        redo_assocs(item.id, params["partitions"])
        render(conn, item: item)

      {:error, conn, code, changeset} ->
        conn
        |> put_status(code)
        |> put_view(DtWeb.ChangesetView)
        |> render(:error, changeset: changeset)
    end
  end

  def update(conn, params) do
    case do_update(conn, params) do
      {:ok, conn, item} ->
        item =
          item
          |> Repo.preload(:partitions)

        render(conn, item: item)

      {:error, _conn, _code} ->
        nil
    end
  end

  defp do_update(conn, %{"id" => nil}), do: {:error, conn, 400}

  defp do_update(conn, params) do
    case Repo.transaction(fn ->
           do_update_in_txn(conn, params)
         end) do
      {:ok, value} ->
        value

      {:error, what} ->
        Logger.error("Got Error #{inspect(what)} in trasaction")
        {:error, conn, 500}
    end
  end

  defp do_update_in_txn(conn, params = %{"id" => sensor_id}) do
    case Repo.get(Sensor, sensor_id) do
      nil ->
        {:error, conn, 404}

      record ->
        redo_assocs(record.id, params["partitions"])

        record
        |> Repo.preload(:partitions)
        |> Sensor.update_changeset(params)
        |> Utils.apply_update(conn)
    end
  end

  defp redo_assocs(_id, nil) do
  end

  defp redo_assocs(id, assocs) do
    q = from(p in PartitionSensor, where: p.sensor_id == ^id)
    Repo.delete_all(q)

    assocs
    |> Enum.each(fn assoc ->
      %PartitionSensor{}
      |> PartitionSensor.changeset(%{partition_id: assoc["id"], sensor_id: id})
      |> Repo.insert!()
    end)
  end
end
