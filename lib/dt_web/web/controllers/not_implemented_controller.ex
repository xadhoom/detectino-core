defmodule DtWeb.NotImplementedController do
  @moduledoc false
  use DtWeb.Web, :controller

  alias Plug.Conn.Status

  def not_impl(conn, _) do
    send_resp(conn, 501, Status.reason_phrase(501))
  end
end
