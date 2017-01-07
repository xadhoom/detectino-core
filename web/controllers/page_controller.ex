defmodule DtWeb.PageController do
  use DtWeb.Web, :controller

  def index(conn, _params) do
    env = Application.get_env(:detectino, :environment)
    |> Atom.to_string
    path = Path.join([
      Application.app_dir(:detectino),
      "priv/static/" <> env <> "/index.html"
    ])
    {:ok, body} = File.read(path)
    html conn, body
  end
end
