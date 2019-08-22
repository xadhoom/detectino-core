defmodule DtWeb.Plugs.AuthPipeline do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :detectino,
    module: DtWeb.Guardian,
    error_handler: DtWeb.Guardian.AuthErrorHandler

  plug(Guardian.Plug.VerifyHeader, realm: "")
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
