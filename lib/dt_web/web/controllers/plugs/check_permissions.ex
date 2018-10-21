defmodule DtWeb.Plugs.CheckPermissions do
  @moduledoc false
  import Plug.Conn

  alias Guardian.Plug, as: GuardianPlug
  alias Plug.Conn.Status

  require Logger

  def init(opts) do
    opts = Enum.into(opts, %{})
    roles = Enum.map(opts.roles, fn role -> Atom.to_string(role) end)
    %{opts | roles: roles}
  end

  def call(conn, opts) do
    case GuardianPlug.claims(conn) do
      {:ok, claims} ->
        check_role(conn, claims, opts)

      _ ->
        conn |> unauthorized()
    end
  end

  def check_role(conn, claims, opts) do
    role = claims |> Map.get("dt_role")

    case Enum.member?(opts.roles, role) do
      false ->
        conn |> forbidden()

      true ->
        conn
    end
  end

  def forbidden(conn) do
    conn
    |> halt
    |> send_resp(403, Status.reason_phrase(403))
  end

  def unauthorized(conn) do
    conn
    |> halt
    |> send_resp(401, Status.reason_phrase(401))
  end
end
