defmodule ExshomePlayerTest.Services.PlaylistTest do
  use Exshome.DataCase, async: true

  alias Exshome.Dependency
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvServer, Playlist}
  import ExshomeTest.Fixtures

  describe "empty tracklist/0" do
    setup do
      ExshomeTest.TestRegistry.start_dependency(Playlist)
    end

    test "shows an empty tracklist" do
      assert [] = Dependency.get_value(Playlist)
    end
  end

  describe "tracklist/0 with tracks" do
    setup do
      generate_random_tracks()
      ExshomeTest.TestRegistry.start_dependency(Playlist)
    end

    test "shows non-empty tracklist" do
      assert Playlist
             |> Dependency.get_value()
             |> Enum.count() > 0
    end
  end

  @spec generate_random_tracks() :: list(String.t())
  defp generate_random_tracks do
    amount = Enum.random(1..10)

    for _ <- 1..amount do
      file_name = "track_#{unique_integer()}.mp3"

      :ok =
        MpvServer.music_folder()
        |> Path.join(file_name)
        |> File.touch!()
    end

    Track.refresh_tracklist()
  end
end
