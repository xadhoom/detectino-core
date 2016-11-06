use Mix.Config

config :dt_core, DtCore.Output.Actions.Email.Mailer,
  adapter: Swoosh.Adapters.Logger,
  level: :debug