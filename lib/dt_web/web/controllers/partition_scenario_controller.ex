defmodule DtWeb.PartitionScenarioController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtCtx.Repo, model: DtCtx.Monitoring.PartitionScenario]

  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]
  plug CoreReloader, nil when not action in [:index, :show]

end
