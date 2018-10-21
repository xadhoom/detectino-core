defmodule DtWeb.NotImplementedController do
  use DtWeb.Web, :controller

  alias Plug.Conn.Status

  def not_impl(conn, _) do
    send_resp(conn, 501, Status.reason_phrase(501))
  end
end
