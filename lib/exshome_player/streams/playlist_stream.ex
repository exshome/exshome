defmodule ExshomePlayer.Streams.PlaylistStream do
  @moduledoc """
  DataStream for playlist changes.
  """
  alias Exshome.Dependency
  alias ExshomePlayer.Services.Playlist
  use Exshome.DataStream, "playlist_tracks"

  @impl DataStream
  def handle_get_value do
    case Dependency.get_value(Playlist) do
      %Playlist{tracks: tracks} -> tracks
      value -> value
    end
  end
end
