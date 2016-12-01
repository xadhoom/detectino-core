defmodule DtWeb.ScenarioController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [repo: DtWeb.Repo, model: DtWeb.Scenario]

  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.StatusCodes
  alias DtWeb.Scenario
  alias DtWeb.User
  alias DtWeb.Partition
  alias Guardian.Plug.EnsureAuthenticated

  require Logger

  plug EnsureAuthenticated,
    [handler: SessionController] when not action in [:get_available, :arm]
  plug CoreReloader, nil when not action in [:index, :show]

  def get_available(conn, params) do
    scenarios = Repo.all(Scenario)
    |> Repo.preload(:partitions)
    |> Enum.filter(fn scenario ->
      case Enum.count(scenario.partitions) do
        0 -> false
        _ -> true
      end
    end)
    render(conn, items: scenarios)
  end

  def arm(conn, params = %{"id" => id, "pin" => pin}) do
    code = case Repo.get(Scenario, id) do
      nil -> 404
      record ->
        check_user(record, pin)
        |> do_arm
    end
    send_resp(conn, code, StatusCodes.status_code(code))
  end

  defp check_user(scenario, pin) do
    u = from(u in User, where: u.pin == ^pin)
    |> Repo.one

    case u do
      nil -> nil
      _ -> scenario |> Repo.preload(:partitions)
    end
  end

  defp do_arm(scenario) do
    case scenario do
      nil -> 401
      x ->
        {ret, _any} = Repo.transaction(fn ->
          x.partitions
          |> Enum.all?(fn(partition) ->
            {ret, struct_or_cset} = partition
            |> Partition.arm
            |> Repo.update
            case ret do
              :ok ->
                true
              :error ->
                Logger.error("Cannot update: #{inspect struct_or_cset}")
                Repo.rollback(:cannot_arm_partition)
                false
            end
          end)
        end)
        case ret do
          :ok -> 204
          _ -> 500
        end
    end
  end

end
