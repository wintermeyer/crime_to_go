import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :crime_to_go, CrimeToGo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "crime_to_go_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :crime_to_go, CrimeToGoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "TNWl7pG3Hehn+H9k0htBiH0LkMH6glvav3UeaDoYvqvUDDxBklq5AE8/mN2gK0xE",
  server: false

# In test we don't send emails
config :crime_to_go, CrimeToGo.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Configure offline debouncing for tests (shorter for faster tests)
config :crime_to_go, offline_debounce_ms: 100

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
