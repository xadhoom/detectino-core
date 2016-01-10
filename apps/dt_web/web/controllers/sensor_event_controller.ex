defmodule DtWeb.SensorEventController do
  use DtWeb.Web, :controller

  alias DtWeb.SensorEvent
  alias DtWeb.SessionController
  alias Guardian.Plug.EnsureAuthenticated

  plug :scrub_params, "sensor_event" when action in [:create, :update]
  plug EnsureAuthenticated, on_failure: {SessionController, :unauthenticated_api} #when not action in [:new, :create]

  def index(conn, _params) do
    sensor_events = Repo.all(SensorEvent)
    render(conn, "index.json", sensor_events: sensor_events)
  end

  def create(conn, %{"sensor_event" => sensor_event_params}) do
    changeset = SensorEvent.create_changeset(%SensorEvent{}, sensor_event_params)

    case Repo.insert(changeset) do
      {:ok, sensor_event} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", sensor_event_path(conn, :show, sensor_event))
        |> render("show.json", sensor_event: sensor_event)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(DtWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    sensor_event = Repo.get!(SensorEvent, id)
    render(conn, "show.json", sensor_event: sensor_event)
  end

  def update(conn, %{"id" => id, "sensor_event" => sensor_event_params}) do
    sensor_event = Repo.get!(SensorEvent, id)
    changeset = SensorEvent.changeset(sensor_event, sensor_event_params)

    case Repo.update(changeset) do
      {:ok, sensor_event} ->
        render(conn, "show.json", sensor_event: sensor_event)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(DtWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    sensor_event = Repo.get!(SensorEvent, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(sensor_event)

    send_resp(conn, :no_content, "")
  end
end
