defmodule ExshomePlayer.Router do
  @moduledoc """
  Routes for player application.
  """

  use Exshome.Behaviours.RouterBehaviour, key: "player"

  alias ExshomePlayer.Web.Live

  scope "/app/player" do
    live "/player", Live.Player
    live "/playlist", Live.Playlist
  end
end
