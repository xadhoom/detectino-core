defmodule Detectino.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :detectino,
      version: "0.0.2",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      releases: [
        detectino: [
          include_executables_for: [:unix]
        ]
      ],
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
    [
      extra_applications: [:logger],
      mod: {Detectino.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, "~> 0.11"},
      {:phoenix_html, "~> 2.13"},
      {:jason, "~> 1.1"},
      {:gettext, "~> 0.9"},
      {:plug_cowboy, "~> 2.1"},
      {:guardian, "~> 2.0"},
      {:bcrypt_elixir, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:exjsx, "~> 4.0"},
      {:ex_link_header, "~> 0.0.5"},
      {:timex, "~> 3.1"},
      {:ecto_sql, "~> 3.1"},
      {:etimer, git: "https://github.com/xadhoom/etimer", tag: "1.0.0"},
      {:swoosh, "~> 0.9"},
      {:gen_smtp, "~> 0.12"},
      {:can, git: "https://github.com/tonyrog/can.git", tag: "1.3", manager: :rebar},
      {:lager, git: "https://github.com/basho/lager.git", tag: "3.2.2", override: true},
      {:gen_state_machine, "~> 2.0"},
      {:logger_file_backend, "~> 0.0.10"},
      # devel stuff
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.7", only: [:dev, :test]},
      {:meck, git: "https://github.com/eproxus/meck.git", only: [:test]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
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
      "phx.routes": ["phx.routes DtWeb.Router"],
      test: ["ecto.reset", "test"]
    ]
  end
end
