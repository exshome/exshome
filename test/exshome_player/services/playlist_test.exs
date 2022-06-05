defmodule ExshomePlayerTest.Services.PlaylistTest do
  use Exshome.DataCase, async: true

  alias Exshome.Dependency
  alias ExshomePlayer.Services.Playlist
  import ExshomeTest.TestMpvServer

  describe "empty tracklist/0" do
    setup do
      ExshomeTest.TestRegistry.start_dependency(Playlist)
    end

    test "shows an empty tracklist" do
      assert %Playlist{tracks: [], current_id: nil} = Dependency.get_value(Playlist)
    end
  end

  describe "tracklist/0 with tracks" do
    setup do
      generate_random_tracks()
      ExshomeTest.TestRegistry.start_dependency(Playlist)
    end

    test "shows non-empty tracklist" do
      assert %Playlist{tracks: tracks} = Dependency.get_value(Playlist)
      assert Enum.count(tracks) > 0
    end
  end
end
