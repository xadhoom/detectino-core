use Mix.Config
config :detectino, :environment, :dev

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :detectino, DtWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  #code_reloader: true,
  cache_static_lookup: false,
  check_origin: false
  #watchers: [sh: ["watcher"]]

# Watch static and templates for browser reloading.
#config :detectino, DtWeb.Endpoint,
#  live_reload: [
#    patterns: [
#      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
#      ~r{web/views/.*(ex)$},
#      ~r{web/templates/.*(eex)$}
#    ]
#  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, metadata: [:pid]

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :detectino, DtWeb.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "dt_web_dev",
  hostname: "localhost",
  pool_size: 10

config :detectino, DtCore.Output.Actions.Email.Mailer,
  adapter: Swoosh.Adapters.Logger,
  level: :debug

config :detectino, :can_interface, "vcan0"
