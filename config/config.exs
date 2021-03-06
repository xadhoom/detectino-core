import Config
config :detectino, :environment, Mix.env()

# Configures the endpoint
config :detectino, DtWeb.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "8usHTvLjCzv3Qm+xXkKfqXnxosWMTbu6idGkv7xYRXMtBmu7SJDBfj5OZjGVGtur",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: DtWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger,
  backends: [:console, {LoggerFileBackend, :file_log}]

config :logger, :file_log,
  format: "$date $time $metadata[$level] $message\n",
  path: "/tmp/detectino.log",
  metadata: [:pid]

config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:request_id, :pid]

# Lager -> Logger redirects
# Stop lager redirecting :error_logger messages
config :lager, :error_logger_redirect, false

# Stop lager removing Logger's :error_logger handler
config :lager, :error_logger_whitelist, [Logger.ErrorHandler]

# Stop lager writing a crash log
config :lager, :crash_log, false

# Use LagerLogger as lager's only handler.
config :lager, :handlers, [{DtLogger.LagerLogger, [{:level, :debug}]}]
# End of lager redirects

# Configure phoenix json lib
config :phoenix, :json_library, Jason

# Custom HTTP Error Codes
config :plug, :statuses, %{555 => "Partition tripped", 556 => "No partitions for scenario"}

config :detectino, DtWeb.Guardian,
  issuer: "DtWeb",
  ttl: {1, :days},
  verify_issuer: true,
  secret_key: "changemeabsolutelyyaddayadda"

# Import notification specific configuration
import_config "notifications.exs"

# Ecto repos
config :detectino, ecto_repos: [DtCtx.Repo]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
