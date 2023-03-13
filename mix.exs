defmodule Exshome.MixProject do
  use Mix.Project

  @source_url "https://github.com/exshome/exshome"
  @version "0.1.7"

  def project do
    [
      aliases: aliases(),
      app: :exshome,
      compilers: Mix.compilers(),
      deps: deps(),
      description: description(),
      dialyzer: [
        check_plt: true,
        plt_add_apps: [:mix, :ex_unit]
      ],
      docs: docs(),
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @source_url,
      name: "Exshome - Elixir Smart Home",
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        dialyzer: :test,
        docs: :test
      ],
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      test_coverage: [
        tool: ExCoveralls
      ],
      version: @version
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :erlexec],
      mod: {Exshome.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.7"},
      {:ecto_sqlite3, "~> 0.9.1"},
      {:erlexec, "~> 2.0"},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.27", only: :test, runtime: false},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:nimble_options, "~> 1.0"},
      {:phoenix, "~> 1.6.5"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18"},
      {:plug_cowboy, "~> 2.5"},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:tz, "~> 0.22"},
      {:tz_extra, "~> 0.22"}
    ]
  end

  defp description do
    "DIY Elixir-based smart home."
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md",
        "guides/install_sbc.md"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_modules: [
        Core: ~r/(^(ExshomeWeb|Exshome\.))|^Exshome$/,
        Tests: ~r/^ExshomeTest.*/,
        Clock: ~r/^ExshomeClock.*/,
        Player: ~r/^ExshomePlayer.*/
      ],
      groups_for_extras: [
        Guides: ~r/guides\/[^\/]+\.md/
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      name: "exshome",
      licenses: ["MIT"],
      files:
        ~w(assets config lib priv test/**/*.ex .formatter.exs mix.exs mix.lock README.md LICENSE.md CHANGELOG.md),
      links: %{"GitHub" => @source_url}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "assets.deploy": [
        "phx.digest.clean",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "esbuild default --minify",
        "tailwind default --minify",
        "phx.digest"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "hex.build": [
        "assets.deploy",
        "format --check-formatted",
        "cmd MIX_ENV=test mix test",
        "hex.build"
      ],
      setup: ["deps.get"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
