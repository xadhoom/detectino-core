defmodule DtWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :detectino

  socket("/socket", DtWeb.Sockets.Socket)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: {:detectino, "priv/static/"},
    gzip: false
  )

  # only:
  # ~w(app.html app.js components index.html init.js lib services styles)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  # if code_reloading? do
  #  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
  # plug Phoenix.LiveReloader
  # plug Phoenix.CodeReloader
  # end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(Plug.Session,
    store: :cookie,
    key: "_dt_web_key",
    signing_salt: "988S/Q54"
  )

  plug(DtWeb.Router)
end
