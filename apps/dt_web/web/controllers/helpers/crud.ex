defmodule DtWeb.CtrlHelpers.Crud do

  import Plug.Conn

  def all(conn, _params, repo, model) do
    items = repo.all(model)
    total = Enum.count(items)
    |> Integer.to_string
    conn = put_resp_header(conn, "x-total-count", total)
    {conn, items}
  end

end
