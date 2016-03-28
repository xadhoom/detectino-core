defmodule DtWeb.SensorController do
  use DtWeb.Web, :controller

  alias DtWeb.Sensor
  alias DtWeb.SessionController
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController] #when not action in [:new, :create]

  plug :scrub_params, "sensor" when action in [:create, :update]

  def index(conn, _params) do
    sensors = Repo.all(Sensor)
    render(conn, "index.html", sensors: sensors)
  end

  def show(conn, %{"id" => id}) do
    sensor = Repo.get!(Sensor, id)
    render(conn, "show.html", sensor: sensor)
  end

  def edit(conn, %{"id" => id}) do
    sensor = Repo.get!(Sensor, id)
    changeset = Sensor.changeset(sensor)
    render(conn, "edit.html", sensor: sensor, changeset: changeset)
  end

  def update(conn, %{"id" => id, "sensor" => sensor_params}) do
    sensor = Repo.get!(Sensor, id)
    changeset = Sensor.changeset(sensor, sensor_params)

    case Repo.update(changeset) do
      {:ok, sensor} ->
        conn
        |> put_flash(:info, "Sensor updated successfully.")
        #|> redirect(to: sensor_path(conn, :show, sensor))
      {:error, changeset} ->
        render(conn, "edit.html", sensor: sensor, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    sensor = Repo.get!(Sensor, id)

    Repo.delete!(sensor)

    conn
    |> put_flash(:info, "Sensor deleted successfully.")
    #|> redirect(to: sensor_path(conn, :index))
  end
end
