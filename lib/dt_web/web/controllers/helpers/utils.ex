defmodule DtWeb.Controllers.Helpers.Utils do
  @moduledoc false
  use DtWeb.Web, :controller

  require Logger

  @doc "run the update and set correct response statuses"
  def apply_update(changeset, conn) do
    case Repo.update(changeset) do
      {:ok, record} ->
        conn = put_status(conn, 200)
        {:ok, conn, record}
      {:error, changeset} ->
        Logger.error "Got error in update changeset: #{inspect changeset}"
        {:error, conn, 400}
    end
  end
end
