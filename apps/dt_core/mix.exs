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
  def application do
    case Mix.env do
      :test -> [applications: [:logger, :swoosh, :etimer]]
      _ -> [applications: [:logger, :swoosh, :gen_smtp, :etimer],
        mod: {DtCore, []}
      ]
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:registry, git: "https://github.com/elixir-lang/registry"},
      {:etimer, git: "https://github.com/xadhoom/etimer", tag: "0.1.0"},
      {:swoosh, "~> 0.5.0"},
      {:gen_smtp, "~> 0.11.0"},
      {:dt_bus, in_umbrella: true},
      {:dt_web, in_umbrella: true},
      {:credo, "~> 0.4", only: [:dev, :test]},
      {:meck, "~> 0.8", only: [:test]}
    ]
  end
end
