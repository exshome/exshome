import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :exshome, ExshomeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "McB+GRVaMaeC1KOJLkJLw7XbjJCuCJn9lwIWVdh3orgUOdLMhtohdySqbKg2ddi3",
  server: false

config :exshome, :environment, :test
config :exshome, Exshome.PubSub, ExshomeTest.TestHooks
config :exshome, :service_pid_getter, ExshomeTest.TestHooks
config :exshome, :service_init_hook_module, ExshomeTest.TestHooks
config :exshome, :live_view_hooks, [ExshomeTest.TestHooks]

config :exshome, :application_children, [
  ExshomeTest.TestRegistry
]

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
