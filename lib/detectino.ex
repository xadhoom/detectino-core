defmodule Detectino do
  use Application

  alias DtWeb.ReloadRegistry
  alias DtWeb.Endpoint

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Endpoint, []),
      # Start the Ecto repository
      supervisor(DtWeb.Repo, []),
      supervisor(DtBus.CanSup, []),
      supervisor(Registry,
        [:duplicate, ReloadRegistry.registry,
          [partitions: System.schedulers_online]],
        restart: :permanent),
    ]

    children = case Mix.env do
      :test -> children
      _ -> children ++ [supervisor(DtCore.Sup, [])]
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
end
