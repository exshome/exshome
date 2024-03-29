defmodule ExshomePlayer.Router do
  @moduledoc """
  Routes for player application.
  """

  alias ExshomePlayer.Live

  @key "player"
  @prefix "/app/#{@key}"

  use Exshome.Behaviours.RouterBehaviour,
    app: ExshomePlayer,
    key: @key,
    main_path: "#{@prefix}/player",
    navbar: [
      [
        path: "#{@prefix}/player",
        name: "player",
        icon: "hero-musical-note-mini"
      ],
      [
        path: "#{@prefix}/playlist",
        name: "playlist",
        icon: "hero-list-bullet-mini",
        extra_views: [Live.Playlist]
      ]
    ],
    preview: Live.Preview

  scope @prefix, Live do
    live_session ExshomePlayer, on_mount: [ExshomeWeb.Live.Navigation] do
      live "/player", Player
      live "/playlist", Playlist, :index
      live "/playlist/upload-file", Playlist, :upload_file
      live "/playlist/add-link", Playlist, :add_link
      live "/playlist/edit-link/:id", Playlist, :edit_link
    end
  end
end
