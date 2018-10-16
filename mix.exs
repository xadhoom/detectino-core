defmodule Detectino.Mixfile do
  use Mix.Project

  def project do
    [
      app: :detectino,
      version: "0.0.2",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_add_deps: :project],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.travis": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    # TODO: this long list should is not needed anymore
    apps = [
      :logger,
      :logger_file_backend,
      :phoenix,
      :phoenix_pubsub,
      :phoenix_html,
      :cowboy,
      :gettext,
      :phoenix_ecto,
      :postgrex,
      :timex,
      :swoosh,
      :etimer,
      :can,
      :guardian,
      :lager_logger,
      :exjsx,
      :comeonin,
      :ex_link_header,
      :plug,
      :dthread,
      :gen_state_machine,
      :runtime_tools
    ]

    prod_apps = apps ++ [:gen_smtp]

    case Mix.env() do
      :test -> [mod: {Detectino, []}, applications: apps]
      _ -> [mod: {Detectino, []}, applications: prod_apps]
    end
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, "~> 0.11"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:poison, "~> 2.2"},
      {:gettext, "~> 0.9"},
      {:cowboy, "~> 1.0"},
      {:guardian, "~> 0.14"},
      {:comeonin, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:exjsx, "~> 4.0"},
      {:ex_link_header, "~> 0.0.5"},
      {:timex, "~> 3.1"},
      {:ecto, "~> 2.1"},
      {:etimer, git: "https://github.com/xadhoom/etimer", tag: "1.0.0"},
      {:swoosh, "~> 0.9"},
      {:gen_smtp, "~> 0.12"},
      {:can, git: "https://github.com/tonyrog/can.git", tag: "1.2", manager: :rebar},
      {:lager, git: "https://github.com/basho/lager.git", override: true},
      {:lager_logger, "~> 1.0"},
      {:gen_state_machine, "~> 2.0"},
      {:logger_file_backend, "~> 0.0.10"},
      # devel stuff
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:excoveralls, "~> 0.7", only: [:dev, :test]},
      {:meck, git: "https://github.com/eproxus/meck.git", only: [:test]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      # release stuff
      {:distillery, "~> 1.5"},
      {:conform, "~> 2.3"}
    ]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate": ["ecto.create -r DtCtx.Repo", "ecto.migrate -r DtCtx.Repo"],
      "phoenix.routes": ["phoenix.routes DtWeb.Router"],
      test: ["ecto.create -r DtCtx.Repo", "ecto.migrate -r DtCtx.Repo", "test"]
    ]
  end
end
