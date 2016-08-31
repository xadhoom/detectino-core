defmodule DtWeb.SensorController do
  use DtWeb.Web, :controller

  alias DtWeb.Sensor
  alias DtWeb.SessionController
  alias DtWeb.StatusCodes
  alias DtWeb.CtrlHelpers.Crud

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]

  def index(conn, params) do
    case Crud.all(conn, params, Repo, Sensor) do
      {:ok, conn, items} -> render(conn, items: items)
      {:error, conn, code} -> send_resp(conn, code, StatusCodes.status_code(code))
    end
  end

  def create(conn, params) do
    case Crud.create(conn, params, User, Sensor, :sensor_path) do
      {:ok, conn, item} -> render(conn, item: item)
      {:error, conn, code, changeset} ->
        conn
        |> put_status(code)
        |> render(DtWeb.ChangesetView, :error, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    case Crud.show(conn, id, Sensor, Repo) do
      {:ok, conn, item} -> render(conn, item: item)
      {:error, conn, code} -> send_resp(conn, code, StatusCodes.status_code(code))
    end
  end

  def update(conn, params) do
    case Crud.update(conn, params, Repo, Sensor) do
      {:ok, conn, item} -> render(conn, item: item)
      {:error, conn, code} -> send_resp(conn, code, StatusCodes.status_code(code))
    end
  end

  def delete(conn, params) do
    case Crud.delete(conn, params, Repo, Sensor) do
      {:response, conn, code} -> send_resp(conn, code, StatusCodes.status_code(code))
      {:error, conn, code} -> send_resp(conn, code, StatusCodes.status_code(code))
    end
  end
end
