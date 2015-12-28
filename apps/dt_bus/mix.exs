defmodule DtBus.Mixfile do
  use Mix.Project

  def project do
    [app: :dt_bus,
     version: "0.0.1",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:logger],
      mod: {DtBus, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:can, git: "https://github.com/tonyrog/can.git", tag: "1.2"},
      {:lager, git: "git://github.com/Feuerlabs/lager.git", override: true},
      {:lager_logger, git: "https://github.com/PSPDFKit-labs/lager_logger"}
    ]
  end
end
