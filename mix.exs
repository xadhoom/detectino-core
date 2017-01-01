defmodule Detectino.Mixfile do
  use Mix.Project

  def project do
    [app: :detectino,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test,
       "coveralls.post": :test, "coveralls.travis": :test]
   ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    apps = [
      :phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
      :phoenix_ecto, :postgrex, :timex, :swoosh, :etimer
    ]
    prod_apps = apps ++ [:gen_smtp]
    case Mix.env do
      :test -> [mod: {Detectino, []}, applications: apps]
      _ -> [mod: {Detectino, []}, applications: prod_apps]
    end
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:postgrex, "~> 0.11"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:poison, "~> 2.2"},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
     {:guardian, "~> 0.13"},
     {:comeonin, "~> 2.0"},
     {:uuid, "~> 1.1"},
     {:ex_link_header, "~> 0.0.5"},
     {:timex, "~> 3.1"},
     # remove registry when elixir 1.4 is released
     {:registry, git: "https://github.com/elixir-lang/registry"},
     {:credo, "~> 0.4", only: [:dev, :test]},
     {:ecto, "~> 2.0"},
     {:etimer, git: "https://github.com/xadhoom/etimer", tag: "0.1.0"},
     {:swoosh, "~> 0.5.0"},
     {:gen_smtp, "~> 0.11.0"},
     {:can, git: "https://github.com/tonyrog/can.git", tag: "1.2"},
     {:lager, git: "https://github.com/basho/lager.git", override: true},
     {:lager_logger, "~> 1.0"},
     {:excoveralls, "~> 0.5"},
     {:meck, "~> 0.8", only: [:test]}
   ]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "ecto.migrate": ["ecto.create -r DtWeb.Repo", "ecto.migrate -r DtWeb.Repo"],
     "phoenix.routes": ["phoenix.routes DtWeb.Router"],
     "test": ["ecto.create -r DtWeb.Repo", "ecto.migrate -r DtWeb.Repo", "test"]]
  end

end
