defmodule DtWeb.EventController do
  @moduledoc """
  Controller for manipulating events.

  XXX: check if some funs can be merged with sensor_controller
  """
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtCtx.Repo, model: DtCtx.Outputs.Event]

  alias DtWeb.SessionController
  alias DtCtx.Outputs.Event
  alias DtCtx.Outputs.EventOutput
  alias DtWeb.StatusCodes
  alias DtWeb.CtrlHelpers.Crud
  alias DtWeb.Controllers.Helpers.Utils
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias Guardian.Plug.EnsureAuthenticated

  require Logger

  plug EnsureAuthenticated, [handler: SessionController]
  plug PinAuthorize
  plug CoreReloader, nil when not action in [:index, :show]

  def index(conn, params) do
    order = [:name]
    case Crud.all(conn, params, {Repo, Event, order}, [:outputs]) do
      {:ok, conn, items} ->
        render(conn, items: items)
      {:error, conn, code} ->
        send_resp(conn, code, StatusCodes.status_code(code))
    end
  end

  def create(conn, params) do
    case Crud.create(conn, params, Event, Repo, :user_path, [:outputs]) do
      {:ok, conn, item} ->
        redo_assocs(item.id, params["outputs"])
        render(conn, item: item)
      {:error, conn, code, changeset} ->
        conn
        |> put_status(code)
        |> render(DtWeb.ChangesetView, :error, changeset: changeset)
    end
  end

  def update(conn, params) do
    case do_update(conn, params) do
      {:ok, conn, item} ->
        item = item
        |> Repo.preload(:outputs)
        render(conn, item: item)
      {:error, conn, code} ->
        send_resp(conn, code, StatusCodes.status_code(code))
    end
  end

  defp do_update(conn, params) do
    case Map.get(params, "id") do
      :nil -> {:error, conn, 400}
      id ->
        case Repo.transaction(fn() ->
          case Repo.get(Event, id) do
            nil -> {:error, conn, 404}
            record ->
              redo_assocs(record.id, params["outputs"])
              record
              |> Repo.preload(:outputs)
              |> Event.update_changeset(params)
              |> Utils.apply_update(conn)
          end
        end) do
          {:ok, value} -> value
          {:error, what} ->
            Logger.error "Got Error #{inspect what} in trasaction"
            {:error, conn, 500}
        end
    end
  end

  defp redo_assocs(_id, :nil) do
  end

  defp redo_assocs(id, assocs) do
    q = from(e in EventOutput, where: e.event_id == ^id)
    Repo.delete_all(q)

    assocs
    |> Enum.each(fn(assoc) ->
      %EventOutput{}
      |> EventOutput.changeset(%{output_id: assoc["id"], event_id: id})
      |> Repo.insert!
    end)
  end

end
