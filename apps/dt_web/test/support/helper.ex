defmodule DtWeb.ControllerHelperTest do

  def get_total(conn) do
    Plug.Conn.get_resp_header(conn, "x-total-count")
    |> Enum.at(0)
    |> String.to_integer
  end

end
