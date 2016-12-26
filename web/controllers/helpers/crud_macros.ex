defmodule DtWeb.CrudMacros do
  @moduledoc """
  Injects basic CRUD helpers when used.
  """

  alias DtWeb.CtrlHelpers.Crud
  alias DtWeb.StatusCodes

  defmacro __using__(opts) do

    quote do
      @repo unquote(opts) |> Keyword.get(:repo)
      @model unquote(opts) |> Keyword.get(:model)

      def index(conn, params) do
        case Crud.all(conn, params, @repo, @model) do
          {:ok, conn, items} ->
            render(conn, items: items)
          {:error, conn, code} ->
            send_resp(conn, code, StatusCodes.status_code(code))
        end
      end

      def create(conn, params) do
        case Crud.create(conn, params, @model, @repo, :user_path) do
          {:ok, conn, item} -> render(conn, item: item)
          {:error, conn, code, changeset} ->
            conn
            |> put_status(code)
            |> render(DtWeb.ChangesetView, :error, changeset: changeset)
        end
      end

      def show(conn, %{"id" => id}) do
        case Crud.show(conn, id, @model, @repo) do
          {:ok, conn, item} ->
            render(conn, item: item)
          {:error, conn, code} ->
            send_resp(conn, code, StatusCodes.status_code(code))
        end
      end

      def update(conn, params) do
        case Crud.update(conn, params, @repo, @model) do
          {:ok, conn, item} ->
            render(conn, item: item)
          {:error, conn, code} ->
            send_resp(conn, code, StatusCodes.status_code(code))
        end
      end

      def delete(conn, params) do
        case Crud.delete(conn, params, @repo, @model) do
          {:response, conn, code} ->
            send_resp(conn, code, StatusCodes.status_code(code))
          {:error, conn, code} ->
            send_resp(conn, code, StatusCodes.status_code(code))
        end
      end

      defoverridable [index: 2, create: 2, show: 2, update: 2, delete: 2]

    end

  end

end
