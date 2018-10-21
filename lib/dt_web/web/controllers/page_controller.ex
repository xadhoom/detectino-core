defmodule DtWeb.PageController do
  @moduledoc false
  use DtWeb.Web, :controller

  def index(conn, _params) do
    path =
      Path.join([
        Application.app_dir(:detectino),
        "priv/static/index.html"
      ])

    {:ok, body} = File.read(path)
    html(conn, body)
  end
end
