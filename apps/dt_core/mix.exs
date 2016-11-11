defmodule DtCore.Mixfile do
  use Mix.Project

  def project do
    [app: :dt_core,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, 
       "coveralls.post": :test, "coveralls.travis": :test]
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    case Mix.env do
      :test -> [applications: [:logger, :swoosh, :gproc, :chronos]]
      _ -> [applications: [:logger, :swoosh, :gen_smtp, :gproc, :chronos],
        mod: {DtCore, []}
      ]
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:registry, git: "https://github.com/elixir-lang/registry"},
      {:chronos, git: "https://github.com/lehoff/chronos.git", tag: "0.1.3"},
      {:gproc, "~> 0.6"},
      {:swoosh, "~> 0.5.0"},
      {:gen_smtp, "~> 0.11.0"},
      {:dt_bus, in_umbrella: true},
      {:dt_web, in_umbrella: true},
      {:credo, "~> 0.4", only: [:dev, :test]},
      {:meck, "~> 0.8", only: [:test]}
    ]
  end
end
