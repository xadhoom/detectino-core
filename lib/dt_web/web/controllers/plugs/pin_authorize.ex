defmodule DtWeb.Plugs.PinAuthorize do
  import Plug.Conn
  import Ecto.Query, only: [from: 2]

  alias DtCtx.Repo
  alias DtCtx.Accounts.User
  alias DtWeb.StatusCodes

  require Logger

  def init(default), do: default

  def call(conn, _params) do
    pin = conn |> get_req_header("p-dt-pin") |> Enum.at(0, nil)

    if is_nil(pin) do
      conn |> handle_error
    else
      q = from(u in User, where: u.pin == ^pin)

      case Repo.one(q) do
        nil -> conn |> handle_error
        u -> conn |> put_private(:dt_pin, u)
      end
    end
  end

  def username(conn) do
    case conn.private[:dt_pin] do
      nil -> nil
      u -> u.username
    end
  end

  defp handle_error(conn) do
    conn
    |> halt
    |> send_resp(401, StatusCodes.status_code(401))
  end
end
