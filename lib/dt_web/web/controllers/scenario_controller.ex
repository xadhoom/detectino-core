defmodule DtWeb.ScenarioController do
  @moduledoc false
  use DtWeb.Web, :controller
  use DtWeb.CrudMacros, repo: DtCtx.Repo, model: DtCtx.Monitoring.Scenario, orderby: [:name]

  alias DtCore.Monitor.Partition, as: PartitionProcess
  alias DtCtx.Accounts.User
  alias DtCtx.Monitoring.Partition
  alias DtCtx.Monitoring.Scenario
  alias DtWeb.Plugs.CheckPermissions
  alias DtWeb.Plugs.CoreReloader
  alias DtWeb.Plugs.PinAuthorize
  alias DtWeb.SessionController
  alias Guardian.Plug.EnsureAuthenticated
  alias Plug.Conn.Status

  require Logger

  plug(EnsureAuthenticated, handler: SessionController)
  plug(CheckPermissions, [roles: [:admin]] when action not in [:get_available, :run])
  plug(PinAuthorize when action not in [:get_available])
  plug(CoreReloader, nil when action not in [:index, :show, :get_available, :run])

  def get_available(conn, _params) do
    q = from(s in Scenario, where: s.enabled == true)

    scenarios =
      q
      |> Repo.all()
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

    code =
      case Repo.get(Scenario, id) do
        nil ->
          404

        record ->
          record
          |> check_user(pin)
          |> run_scenario()
      end

    send_resp(conn, code, Status.reason_phrase(code))
  end

  defp check_user(scenario, pin) do
    q = from(u in User, where: u.pin == ^pin)
    u = Repo.one(q)

    case u do
      nil ->
        nil

      user ->
        newscenario = Repo.preload(scenario, :partitions_scenarios)
        {newscenario, user}
    end
  end

  defp run_scenario({nil, _user}), do: 401

  defp run_scenario({scenario, user}) do
    partitions_scenarios = scenario.partitions_scenarios

    case Enum.count(partitions_scenarios) do
      0 ->
        556

      _ ->
        partitions_scenarios
        |> run_scenario_in_txn(user)
        |> case do
          {:ok, _} -> 204
          {:error, :tripped} -> 555
          _ -> 500
        end
    end
  end

  defp run_scenario_in_txn(partitions_scenarios, user) do
    Repo.transaction(fn ->
      partitions_scenarios
      |> Enum.all?(fn partition_scenario ->
        {ret, struct_or_cset} =
          partition_scenario
          |> run_arm_disarm_op()
          |> Repo.update()

        with :ok <- ret,
             :ok <- arm_disarm_partition_proc(struct_or_cset, user) do
          :ok
        else
          {:error, :tripped} ->
            Logger.error("Cannot arm, tripped sensor: #{inspect(struct_or_cset)}")
            Repo.rollback(:tripped)

          :error ->
            Logger.error("Cannot update: #{inspect(struct_or_cset)}")
            Repo.rollback(:cannot_arm_partition)
        end
      end)
    end)
  end

  defp arm_disarm_partition_proc(partition, user) do
    case partition.armed do
      "DISARM" ->
        :ok = PartitionProcess.disarm(partition, user.username)

      v ->
        :ok = PartitionProcess.disarm(partition, user.username)
        mode = Partition.arm_mode_str_to_atom(v)
        PartitionProcess.arm(partition, user.username, mode)
    end
  end

  defp run_arm_disarm_op(partition_scenario) do
    mode = partition_scenario.mode
    partition = Repo.get(Partition, partition_scenario.partition_id)

    case Partition.arm_op_from_mode(mode) do
      :arm -> partition |> Partition.arm(mode)
      :disarm -> partition |> Partition.disarm()
    end
  end
end
