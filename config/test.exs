import Config

# Configure your database
config :exshome, Exshome.Repo,
  pool_size: 5,
  show_sensitive_data_on_connection_error: true,
  database_name: "exshome_test.db"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :exshome, ExshomeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "McB+GRVaMaeC1KOJLkJLw7XbjJCuCJn9lwIWVdh3orgUOdLMhtohdySqbKg2ddi3",
  server: false

config :exshome, :environment, :test
config :exshome, Exshome.PubSub, ExshomeTest.Hooks.PubSub
config :exshome, :service_hook_module, ExshomeTest.Hooks.Service
config :exshome, :repo_hook_module, ExshomeTest.Hooks.Repo
config :exshome, :live_view_hooks, [ExshomeTest.Hooks.LiveView]

config :exshome, :application_children, [
  ExshomeTest.TestRegistry
]

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
