defmodule Detectino.Application do
  @moduledoc false
  use Application

  alias DtWeb.Endpoint
  alias DtWeb.ReloadRegistry

  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    run_migrations()

    basic_children = [
      # Start the endpoint when the application starts
      supervisor(Endpoint, []),
      # Start the Ecto repository
      supervisor(DtCtx.Repo, []),
      supervisor(DtBus.CanSup, []),
      supervisor(
        Registry,
        [:duplicate, ReloadRegistry.registry()],
        restart: :permanent
      ),
      worker(DtWeb.TokenServer, [], restart: :permanent)
    ]

    children =
      case Application.get_env(:detectino, :environment) do
        :test -> basic_children
        _ -> basic_children ++ [supervisor(DtCore.Sup, [])]
      end

    opts = [strategy: :one_for_one, name: Detectino.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  # This fn may be used to automatically run migrations when
  # starting the app on production
  defp run_migrations do
    path = Application.app_dir(:detectino) <> "/priv/repo/migrations"

    case Application.get_env(:detectino, :environment) do
      :prod ->
        Logger.info("Running database migrations...")
        {:ok, pid} = DtCtx.Repo.start_link()
        Ecto.Migrator.run(DtCtx.Repo, path, :up, [{:all, true}, {:log, :debug}])
        Process.unlink(pid)
        :ok = DtCtx.Repo.stop(pid)

      v ->
        Logger.info("Not production (#{inspect(v)}, disabling auto database migration")
    end
  end
end
