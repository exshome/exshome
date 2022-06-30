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

config :exshome,
  hooks: [
    {ExshomeWeb.Live.AppPage, ExshomeTest.Hooks.AppPage},
    {Exshome.Dependency.GenServerDependency, ExshomeTest.Hooks.Dependency},
    {Exshome.FileUtils, ExshomeTest.Hooks.FileUtils},
    {ExshomePlayer.Services.MpvServer, ExshomeTest.Hooks.MpvServer},
    {Exshome.PubSub, ExshomeTest.Hooks.PubSub},
    {Exshome.Repo, ExshomeTest.Hooks.Repo},
    {:live_view, [ExshomeTest.Hooks.LiveView]}
  ]

config :exshome, :application_children, []

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
