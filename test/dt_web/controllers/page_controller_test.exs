defmodule DtWeb.PageControllerTest do
  use DtWeb.ConnCase

  test "GET /" do
    conn = get(build_conn(), "/")
    assert html_response(conn, 200)
  end
end
