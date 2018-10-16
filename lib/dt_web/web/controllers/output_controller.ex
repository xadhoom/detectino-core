defmodule DtWeb.OutputController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, repo: DtCtx.Repo, model: DtCtx.Outputs.Output

  alias DtWeb.SessionController
  alias Guardian.Plug.EnsureAuthenticated
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias DtWeb.Plugs.CheckPermissions

  plug(EnsureAuthenticated, handler: SessionController)
  plug(CoreReloader, nil when action not in [:index, :show])
  plug(CheckPermissions, roles: [:admin])
  plug(PinAuthorize)
end
