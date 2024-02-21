defmodule ExshomePlayerTest.Services.PlaylistTest do
  use ExshomeTest.DataCase, async: true

  import ExshomeTest.Fixtures
  import ExshomeTest.TestMpvServer

  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias Exshome.Event
  alias ExshomePlayer.Events.PlayerFileEnd
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, Playlist}
  alias ExshomePlayer.Streams.TrackStream
  alias ExshomePlayer.Variables.Title

  describe "Playlist not started" do
    test "returns NotReady" do
      assert Dependency.get_value(Playlist) == NotReady
    end
  end

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
      tracks = Dependency.get_value(Playlist)
      assert Enum.count(tracks) > 0
    end
  end

  describe "playlist actions" do
    setup do
      server_fixture()
      generate_random_tracks(2..10)
      ExshomeTest.TestRegistry.start_dependency(MpvSocket)
      ExshomeTest.TestRegistry.start_dependency(Playlist)
      tracks = Dependency.get_value(Playlist)
      %{tracks: tracks}
    end

    test "move through tracks", %{tracks: [%Track{id: first_id} | _] = tracks} do
      total_tracks = length(tracks)

      assert nil == get_current_track()

      for _ <- 1..(total_tracks + 1) do
        assert :ok = Playlist.next()
      end

      assert nil == get_current_track()

      for _ <- 1..(total_tracks + 1) do
        assert :ok = Playlist.previous()
      end

      assert %Track{id: ^first_id} = get_current_track()
    end

    test "playlist moves on the end of file", %{
      tracks: [%Track{id: first_id}, %Track{id: second_id} | _]
    } do
      assert :ok = Playlist.play(first_id)
      Event.broadcast(%PlayerFileEnd{reason: "eof"})
      assert %Track{id: ^second_id} = get_current_track()
    end

    test "playlist stays on unknown reason for file end", %{tracks: [%Track{id: id} | _]} do
      assert :ok = Playlist.play(id)
      Event.broadcast(%PlayerFileEnd{reason: "reason #{unique_integer()}"})
      assert %Track{id: ^id} = get_current_track()
    end

    test "playlist stops on deleting current track", %{tracks: [%Track{id: id} = track | _]} do
      assert :ok = Playlist.play(id)
      assert %Track{id: ^id} = get_current_track()
      Track.delete!(track)
      assert nil == get_current_track()
    end

    test "playlist adds a track on new one", %{tracks: tracks} do
      generate_random_tracks(1..1)
      Track.refresh_tracklist()
      new_tracks = Dependency.get_value(Playlist)
      assert length(new_tracks) == length(tracks) + 1
    end

    test "playlist continues on deleting other track", %{
      tracks: [%Track{id: id}, %Track{} = second_track | _] = tracks
    } do
      assert :ok = Playlist.play(id)
      assert %Track{id: ^id} = get_current_track()
      Track.delete!(second_track)
      assert %Track{id: ^id} = get_current_track()
      updated_tracks = Dependency.get_value(Playlist)
      assert length(tracks) > length(updated_tracks)
    end

    test "updates a track title", %{tracks: [%Track{id: id} | _]} do
      assert :ok = Playlist.play(id)
      DataStream.subscribe(TrackStream)
      new_title = "unique_title #{unique_integer()}"
      Dependency.broadcast_value(Title, new_title)

      assert_receive_stream(
        {TrackStream,
         %Operation.Update{
           data: %Track{id: ^id, title: ^new_title}
         }}
      )

      assert %Track{id: ^id, title: ^new_title} = Track.get!(id)

      assert [%Track{id: ^id, title: ^new_title} | _] = Dependency.get_value(Playlist)
    end

    defp get_current_track do
      assert tracks = Dependency.get_value(Playlist)
      playing_tracks = Enum.filter(tracks, & &1.playing?)

      case playing_tracks do
        [] -> nil
        [track] -> track
        _ -> raise "Only one track should be playing at a time"
      end
    end
  end
end
