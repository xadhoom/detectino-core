defmodule DtWeb.ScenarioController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros

  alias DtWeb.Scenario
  alias DtWeb.SessionController

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]

  @repo Repo
  @model Scenario

end
