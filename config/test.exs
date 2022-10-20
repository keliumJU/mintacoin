import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mintacoin, Mintacoin.Repo,
  database: System.get_env("POSTGRES_DB_TEST", "mintacoin_test#{System.get_env("MIX_TEST_PARTITION")}"),
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mintacoin, MintacoinWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "BaUrx1V02yCkmqNpsnmhRxluI5Qt0q6J5of+SWbvJI6kpde8nFb5MbGIYSaW/vYN",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Oban test configuration
config :mintacoin, Oban, testing: :inline

# Encryption variables for accounts signatures
config :mintacoin, encryption_variable: "HQHSCWQ4HNBMLFUWHU2S7H3KGU"

# Stellar SDK configuration
config :stellar_sdk, network: :test

config :mintacoin,
  api_token:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
