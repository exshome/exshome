# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :exshome,
  ecto_repos: [Exshome.Repo],
  generators: [binary_id: true]

# Configure your database
config :exshome, Exshome.Repo,
  migration_timestamps: [type: :utc_datetime_usec],
  cache_size: -2000

config :exshome, :root_folder, Path.expand("../data/", __DIR__)

# Configures the endpoint
config :exshome, ExshomeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ExshomeWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Exshome.PubSub,
  live_view: [signing_salt: "zS+/EC9L"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Tailwind config
config :tailwind,
  version: "3.0.23",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :exshome, :application_children, [
  {Exshome.App.Clock.UtcTime, %{refresh_interval: 200}},
  {Exshome.App.Clock.LocalTime, %{}},
  {Exshome.App.Player.MpvServer, %{}},
  {Exshome.App.Player.MpvSocket, %{on_event: &Exshome.App.Player.MpvClient.on_mpv_event/1}},
  {Exshome.App.Player.MpvClient, %{}},
  {Exshome.App.Player.PlayerState.Path, %{}},
  {Exshome.App.Player.PlayerState.Pause, %{}},
  {Exshome.App.Player.PlayerState.Position, %{}},
  {Exshome.App.Player.PlayerState.Volume, %{}},
  {Exshome.App.Player.PlayerState.Title, %{}},
  {Exshome.App.Player.PlayerState.Duration, %{}}
]

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
