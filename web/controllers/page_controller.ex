defmodule DtWeb.PageController do
  use DtWeb.Web, :controller

  alias DtWeb.Endpoint.Utils

  def index(conn, _params) do
    path = Path.join([
      Application.app_dir(:detectino),
      "priv/static/" <> Utils.get_static_env() <> "/index.html"
    ])
    {:ok, body} = File.read(path)
    html conn, body
  end
end
