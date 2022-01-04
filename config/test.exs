import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :exshome, ExshomeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "McB+GRVaMaeC1KOJLkJLw7XbjJCuCJn9lwIWVdh3orgUOdLMhtohdySqbKg2ddi3",
  server: false

config :exshome, :environment, :test
config :exshome, :clock_refresh_interval, 1_000_000
config :exshome, Exshome.PubSub, &ExshomeTest.Fixtures.test_topic_name/1
config :exshome, :live_view_hooks, [ExshomeTest.TestLiveHooks]

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
