defmodule ExshomeClock.Router do
  @moduledoc """
  Routes for clock application.
  """

  alias ExshomeClock.Live

  @key "clock"
  @prefix "/app/#{@key}"

  use Exshome.Behaviours.RouterBehaviour,
    app: ExshomeClock,
    key: @key,
    main_path: "#{@prefix}/clock",
    navbar: [
      [
        path: "#{@prefix}/clock",
        name: "clock",
        icon: "hero-clock-mini"
      ],
      [
        path: "#{@prefix}/settings",
        name: "settings",
        icon: "hero-cog"
      ]
    ],
    preview: Live.Preview

  scope @prefix do
    live_session ExshomeClock, on_mount: [ExshomeWeb.Live.Navigation] do
      live "/clock", Live.Clock
      live "/settings", Live.Settings
    end
  end
end
