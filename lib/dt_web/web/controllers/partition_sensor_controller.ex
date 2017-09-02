defmodule DtWeb.PartitionSensorController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtCtx.Repo, model: DtCtx.Monitoring.Partition]

  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.CheckPermissions
  alias DtWeb.Plugs.PinAuthorize
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]
  plug CoreReloader, nil when not action in [:index, :show]
  plug CheckPermissions, [roles: [:admin]]
  plug PinAuthorize

end
