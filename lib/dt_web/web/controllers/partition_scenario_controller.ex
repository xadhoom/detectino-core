defmodule DtWeb.PartitionScenarioController do
  @moduledoc false
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, repo: DtCtx.Repo, model: DtCtx.Monitoring.PartitionScenario

  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.CheckPermissions
  alias DtWeb.Plugs.PinAuthorize
  alias Guardian.Plug.EnsureAuthenticated

  plug(EnsureAuthenticated, handler: SessionController)
  plug(CoreReloader, nil when action not in [:index, :show])
  plug(CheckPermissions, roles: [:admin])
  plug(PinAuthorize)
end
