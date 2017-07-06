defmodule DtWeb.NotImplementedController do
  use DtWeb.Web, :controller

  alias DtWeb.StatusCodes

  def not_impl(conn, _) do
    send_resp(conn, 501, StatusCodes.status_code(501))
  end

end
