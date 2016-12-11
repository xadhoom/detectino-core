defmodule DtWeb.OutputController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtWeb.Repo, model: DtWeb.Output]

  alias DtWeb.SessionController
  alias Guardian.Plug.EnsureAuthenticated
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize

  plug EnsureAuthenticated, [handler: SessionController]
  plug CoreReloader, nil when not action in [:index, :show]
  plug PinAuthorize

end
