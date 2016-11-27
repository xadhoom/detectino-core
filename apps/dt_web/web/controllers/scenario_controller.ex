defmodule DtWeb.ScenarioController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtWeb.Repo, model: DtWeb.Scenario]

  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias Guardian.Plug.EnsureAuthenticated

  plug EnsureAuthenticated,
    [handler: SessionController] when not action in [:get_available]
  plug CoreReloader, nil when not action in [:index, :show]

  def get_available(conn, params) do
    scenarios = Repo.all(DtWeb.Scenario)
    |> Repo.preload(:partitions)
    |> Enum.filter(fn scenario ->
      case Enum.count(scenario.partitions) do
        0 -> false
        _ -> true
      end
    end)
    render(conn, items: scenarios)
  end

end
