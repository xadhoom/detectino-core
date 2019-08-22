defmodule DtWeb.CrudMacros do
  @moduledoc """
  Injects basic CRUD helpers when used.
  """
  alias DtWeb.CtrlHelpers.Crud
  alias Plug.Conn.Status

  defmacro __using__(opts) do
    quote do
      @repo unquote(opts) |> Keyword.get(:repo)
      @model unquote(opts) |> Keyword.get(:model)
      @orderby unquote(opts) |> Keyword.get(:orderby)

      def index(conn, params) do
        case Crud.all(conn, params, {@repo, @model, @orderby}) do
          {:ok, conn, items} ->
            render(conn, items: items)

          {:error, conn, code} ->
            send_resp(conn, code, Status.reason_phrase(code))
        end
      end

      def create(conn, params) do
        case Crud.create(conn, params, @model, @repo, :user_path) do
          {:ok, conn, item} ->
            render(conn, item: item)

          {:error, conn, code, changeset} ->
            conn
            |> put_status(code)
            |> put_view(DtWeb.ChangesetView)
            |> render(:error, changeset: changeset)
        end
      end

      def show(conn, %{"id" => id}) do
        case Crud.show(conn, id, @model, @repo) do
          {:ok, conn, item} ->
            render(conn, item: item)

          {:error, conn, code} ->
            send_resp(conn, code, Status.reason_phrase(code))
        end
      end

      def update(conn, params) do
        case Crud.update(conn, params, @repo, @model) do
          {:ok, conn, item} ->
            render(conn, item: item)

          {:error, conn, code} ->
            send_resp(conn, code, Status.reason_phrase(code))
        end
      end

      def delete(conn, params) do
        case Crud.delete(conn, params, @repo, @model) do
          {:response, conn, code} ->
            send_resp(conn, code, Status.reason_phrase(code))

          {:error, conn, code} ->
            send_resp(conn, code, Status.reason_phrase(code))
        end
      end

      defoverridable index: 2, create: 2, show: 2, update: 2, delete: 2
    end
  end
end
