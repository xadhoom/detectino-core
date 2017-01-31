defmodule Detectino do
  use Application

  alias DtWeb.ReloadRegistry
  alias DtWeb.Endpoint

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    basic_children = [
      # Start the endpoint when the application starts
      supervisor(Endpoint, []),
      # Start the Ecto repository
      supervisor(DtWeb.Repo, []),
      supervisor(DtBus.CanSup, []),
      supervisor(Registry,
        [:duplicate, ReloadRegistry.registry,
          [partitions: System.schedulers_online]],
        restart: :permanent),
      worker(DtWeb.TokenServer, [], restart: :permanent)
    ]

    children = case Application.get_env(:detectino, :environment) do
      :test -> basic_children
      _ -> basic_children ++ [supervisor(DtCore.Sup, [])]
    end

    opts = [strategy: :one_for_one, name: DtWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  defp run_migrations do
    path = Application.app_dir(:detectino) <> "/priv/repo/migrations"
    Ecto.Migrator.run(DtWeb.Repo, path, :up, [{:all, true}, {:log, :debug}])
  end
end
