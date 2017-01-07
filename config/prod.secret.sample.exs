use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :detectino, DtWeb.Endpoint,
  secret_key_base: "CHANGEME"

# Configure your database
config :detectino, DtWeb.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "dt_web_prod",
  pool_size: 20
