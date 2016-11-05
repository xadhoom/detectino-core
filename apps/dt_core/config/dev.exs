use Mix.Config

config :dt_core, DtCore.Output.Actions.Email,
  adapter: Swoosh.Adapters.Logger,
  level: :debug