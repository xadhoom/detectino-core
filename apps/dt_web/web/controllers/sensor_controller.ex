defmodule DtWeb.SensorController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros

  alias DtWeb.Sensor
  alias DtWeb.SessionController

  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated, [handler: SessionController]

  @repo Repo
  @model Sensor

end
