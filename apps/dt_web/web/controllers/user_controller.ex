defmodule DtWeb.UserController do
  use DtWeb.Web, :controller

  alias DtWeb.User
  alias DtWeb.SessionController
  alias DtWeb.StatusCodes
  alias DtWeb.CtrlHelpers.Crud

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]

  def index(conn, params) do
    {conn, users} = Crud.all(conn, params, Repo, User)
    render(conn, users: users)
  end

  def create(conn, params) do
    changeset = User.create_changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_resp_header("location", user_path(conn, :show, user))
        |> put_status(201)
        |> render(user: user)
      {:error, changeset} ->
        send_resp(conn, 400, StatusCodes.status_code(400))
    end
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)
    case user do
      nil -> send_resp(conn, 404, StatusCodes.status_code(404))
      _ -> render(conn, user: user)
    end
  end

  def update(conn, params) do
    id = case Map.get(params, "id") do
      :nil -> send_resp(conn, 400, StatusCodes.status_code(400))
      v -> v
    end
    user = Repo.get!(User, id)
    changeset = User.update_changeset(user, params)

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_status(200)
        |> render(user: user)
      {:error, changeset} ->
        send_resp(conn, 400, StatusCodes.status_code(400))
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    #|> redirect(to: user_path(conn, :index))
  end
end
