defmodule ExshomePlayerTest.Services.PlaylistNewTest do
  use ExshomeTest.DataCase, async: true

  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.PlaylistNew
  import ExshomeTest.TestMpvServer

  describe "empty tracklist/0" do
    setup do
      ExshomeTest.TestRegistry.start_dependency(PlaylistNew)
    end

    test "shows an empty tracklist" do
      assert %Operation.ReplaceAll{data: []} = Dependency.get_value(PlaylistNew)
    end
  end

  describe "tracklist/0 with existing tracks" do
    setup do
      generate_random_tracks()
      ExshomeTest.TestRegistry.start_dependency(PlaylistNew)
    end

    test "shows non-empty tracklist" do
      assert %Operation.ReplaceAll{data: tracks} = Dependency.get_value(PlaylistNew)
      assert Enum.count(tracks) > 0
    end
  end

  describe "tracklist/0 with new tracks" do
    setup do
      ExshomeTest.TestRegistry.start_dependency(PlaylistNew)
      generate_random_tracks()
      Track.refresh_tracklist()
    end

    test "shows non-empty tracklist" do
      assert %Operation.ReplaceAll{data: tracks} = Dependency.get_value(PlaylistNew)
      assert Enum.count(tracks) > 0
    end
  end
end
