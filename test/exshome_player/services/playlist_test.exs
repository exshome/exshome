defmodule ExshomePlayerTest.Services.PlaylistTest do
  use ExshomeTest.DataCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Event
  alias ExshomePlayer.Events.PlayerFileEnd
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, Playlist}
  alias ExshomePlayer.Streams.TrackStream
  alias ExshomePlayer.Variables.Title
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

  describe "playlist actions" do
    setup do
      server_fixture()
      generate_random_tracks(2..10)
      ExshomeTest.TestRegistry.start_dependency(MpvSocket)
      ExshomeTest.TestRegistry.start_dependency(Playlist)
      %Playlist{tracks: tracks} = Dependency.get_value(Playlist)
      %{tracks: tracks}
    end

    test "move through tracks", %{tracks: [%Track{id: id} | _] = tracks} do
      total_tracks = length(tracks)

      assert :ok = Playlist.play(id)

      for _ <- 1..(total_tracks + 1) do
        assert :ok = Playlist.next()
      end

      assert %Playlist{current_id: nil} = Dependency.get_value(Playlist)

      for _ <- 1..(total_tracks + 1) do
        assert :ok = Playlist.previous()
      end

      assert %Playlist{current_id: ^id} = Dependency.get_value(Playlist)
    end

    test "playlist moves on the end of file", %{
      tracks: [%Track{id: first_id}, %Track{id: second_id} | _]
    } do
      assert :ok = Playlist.play(first_id)
      Event.broadcast(%PlayerFileEnd{reason: "eof"})
      assert %Playlist{current_id: ^second_id} = Dependency.get_value(Playlist)
    end

    test "playlist stays on unknown reason for file end", %{tracks: [%Track{id: id} | _]} do
      assert :ok = Playlist.play(id)
      Event.broadcast(%PlayerFileEnd{reason: "reason #{unique_integer()}"})
      assert %Playlist{current_id: ^id} = Dependency.get_value(Playlist)
    end

    test "playlist stops on deleting current track", %{tracks: [%Track{id: id} = track | _]} do
      assert :ok = Playlist.play(id)
      Track.delete!(track)
      assert %Playlist{current_id: nil} = Dependency.get_value(Playlist)
    end

    test "playlist adds a track on new one", %{tracks: tracks} do
      generate_random_tracks(1..1)
      Track.refresh_tracklist()
      %Playlist{tracks: new_tracks} = Dependency.get_value(Playlist)
      assert length(new_tracks) == length(tracks) + 1
    end

    test "playlist continues on deleting other track", %{
      tracks: [%Track{id: id}, second_track | _] = tracks
    } do
      assert :ok = Playlist.play(id)
      Track.delete!(second_track)
      assert %Playlist{current_id: ^id, tracks: updated_tracks} = Dependency.get_value(Playlist)
      assert length(tracks) > length(updated_tracks)
    end

    test "updates a track title", %{tracks: [%Track{id: id} | _]} do
      assert :ok = Playlist.play(id)
      new_title = "unique_title #{unique_integer()}"
      Dependency.subscribe(TrackStream)
      Dependency.broadcast_value(Title, new_title)

      assert_receive_stream(%Operation.Update{id: ^id, data: %Track{id: ^id}})

      assert %Track{id: ^id, title: ^new_title} = Track.get!(id)

      assert %Playlist{tracks: [%Track{id: ^id, title: ^new_title} | _]} =
               Dependency.get_value(Playlist)
    end
  end
end
