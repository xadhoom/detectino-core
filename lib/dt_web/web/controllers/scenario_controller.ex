defmodule DtWeb.ScenarioController do
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, [
    repo: DtWeb.Repo, model: DtWeb.Scenario, orderby: [:name]
  ]

  alias DtWeb.SessionController
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias DtWeb.StatusCodes
  alias DtWeb.Scenario
  alias DtCtx.Accounts.User
  alias DtWeb.Partition
  alias DtCore.Monitor.Partition, as: PartitionProcess
  alias Guardian.Plug.EnsureAuthenticated

  require Logger

  plug EnsureAuthenticated, [handler: SessionController]
  plug PinAuthorize when not action in [:get_available]
  plug CoreReloader, nil when not action in [
    :index, :show, :get_available, :run]

  def get_available(conn, _params) do
    q = from s in Scenario, where: s.enabled == true
    scenarios = q
    |> Repo.all
    |> Repo.preload(:partitions)
    |> Enum.filter(fn scenario ->
      case Enum.count(scenario.partitions) do
        0 -> false
        _ -> true
      end
    end)
    render(conn, items: scenarios)
  end

  def run(conn, %{"id" => id}) do
    pin = conn |> get_req_header("p-dt-pin") |> Enum.at(0, nil)
    code = case Repo.get(Scenario, id) do
      nil -> 404
      record ->
        record
        |> check_user(pin) # TODO: why? the PinAuthorize should do that for us.
        |> run_scenario()
    end
    send_resp(conn, code, StatusCodes.status_code(code))
  end

  defp check_user(scenario, pin) do
    q = from(u in User, where: u.pin == ^pin)
    u = Repo.one(q)

    case u do
      nil -> nil
      _ ->
        scenario
        |> Repo.preload(:partitions_scenarios)
    end
  end

  defp run_scenario(scenario) do
    case scenario do
      nil -> 401
      x ->
        case Enum.count(x.partitions_scenarios) do
          0 -> 403
          _ ->
            {ret, _any} = x.partitions_scenarios
            |> run_scenario_in_txn()
            case ret do
              :ok -> 204
              _ -> 500
            end
        end
    end
  end

  defp run_scenario_in_txn(partitions_scenarios) do
    Repo.transaction(fn ->
      partitions_scenarios
      |> Enum.all?(fn(partition_scenario) ->
        {ret, struct_or_cset} = partition_scenario
        |> run_arm_disarm_op()
        |> Repo.update
        case ret do
          :ok ->
            arm_disarm_partition_proc(struct_or_cset)
            true
          :error ->
            Logger.error("Cannot update: #{inspect struct_or_cset}")
            Repo.rollback(:cannot_arm_partition)
            false
        end
      end)
    end)
  end

  defp arm_disarm_partition_proc(partition) do
    case partition.armed do
      "DISARM" ->
        PartitionProcess.disarm(partition)
      v ->
        PartitionProcess.arm(partition, v)
    end
  end

  defp run_arm_disarm_op(partition_scenario) do
    mode = partition_scenario.mode
    partition = Repo.get(Partition, partition_scenario.partition_id)
    case Partition.arm_op_from_mode(mode) do
      :arm -> partition |> Partition.arm(mode)
      :disarm -> partition |> Partition.disarm
    end
  end

end
