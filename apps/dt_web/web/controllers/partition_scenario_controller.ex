defmodule DtWeb.PartitionScenarioController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros

  alias DtWeb.PartitionScenario
  alias DtWeb.SessionController

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]

  @repo Repo
  @model PartitionScenario

end
