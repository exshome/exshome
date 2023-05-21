defmodule ExshomePlayerTest.Services.PlaylistNewTest do
  use ExshomeTest.DataCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Event
  alias ExshomePlayer.Events.{PlayerFileEnd, TrackEvent}
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, PlaylistNew}
  alias ExshomePlayer.Variables.Title
  import ExshomeTest.TestMpvServer

  describe "empty tracklist/0" do
    setup do
      ExshomeTest.TestRegistry.start_dependency(PlaylistNew)
    end

    test "shows an empty tracklist" do
      assert [] = get_tracks()
    end
  end

  describe "tracklist/0 with existing tracks" do
    setup do
      generate_random_tracks()
      ExshomeTest.TestRegistry.start_dependency(PlaylistNew)
    end

    test "shows non-empty tracklist" do
      assert Enum.count(get_tracks()) > 0
    end
  end

  describe "tracklist/0 with new tracks" do
    setup do
      ExshomeTest.TestRegistry.start_dependency(PlaylistNew)
      generate_random_tracks()
      Track.refresh_tracklist()
    end

    test "shows non-empty tracklist" do
      assert Enum.count(get_tracks()) > 0
    end
  end

  describe "playlist actions" do
    setup do
      server_fixture()
      generate_random_tracks(2..10)
      ExshomeTest.TestRegistry.start_dependency(MpvSocket)
      ExshomeTest.TestRegistry.start_dependency(PlaylistNew)
      %{tracks: get_tracks()}
    end

    test "move through tracks", %{tracks: [%Track{id: id} | _] = tracks} do
      total_tracks = length(tracks)

      assert :ok = PlaylistNew.play(id)

      assert get_current_track() != nil

      for _ <- 1..(total_tracks + 1) do
        assert :ok = PlaylistNew.next()
      end

      assert nil == get_current_track()

      for _ <- 1..(total_tracks + 1) do
        assert :ok = PlaylistNew.previous()
      end

      assert %Track{id: ^id} = get_current_track()
    end

    test "playlist moves on the end of file", %{
      tracks: [%Track{id: first_id}, %Track{id: second_id} | _]
    } do
      assert :ok = PlaylistNew.play(first_id)
      Event.broadcast(%PlayerFileEnd{reason: "eof"})
      assert %Track{id: ^second_id} = get_current_track()
    end

    test "playlist stays on unknown reason for file end", %{tracks: [%Track{id: id} | _]} do
      assert :ok = PlaylistNew.play(id)
      Event.broadcast(%PlayerFileEnd{reason: "reason #{unique_integer()}"})
      assert %Track{id: ^id} = get_current_track()
    end

    test "playlist stops on deleting current track", %{tracks: [%Track{id: id} = track | _]} do
      assert :ok = PlaylistNew.play(id)
      Track.delete!(track)
      assert nil == get_current_track()
    end

    test "playlist adds a track on new one", %{tracks: tracks} do
      generate_random_tracks(1..1)
      Track.refresh_tracklist()
      new_tracks = get_tracks()
      assert length(new_tracks) == length(tracks) + 1
    end

    test "playlist continues on deleting other track", %{
      tracks: [%Track{id: id}, second_track | _] = tracks
    } do
      assert :ok = PlaylistNew.play(id)
      Track.delete!(second_track)
      assert %Track{id: ^id} = get_current_track()
      updated_tracks = get_tracks()
      assert length(tracks) > length(updated_tracks)
    end

    test "updates a track title", %{tracks: [%Track{id: id} | _]} do
      assert :ok = PlaylistNew.play(id)
      new_title = "unique_title #{unique_integer()}"
      Dependency.subscribe(TrackEvent)
      Dependency.broadcast_value(Title, new_title)

      assert_receive_event(%TrackEvent{action: :updated, track: %Track{id: ^id}})

      assert %Track{id: ^id, title: ^new_title} = Track.get!(id)

      assert %Track{id: ^id, title: ^new_title} = get_current_track()
    end
  end

  @spec get_current_track() :: Track.t() | nil
  defp get_current_track do
    playing_tracks = Enum.filter(get_tracks(), & &1.playing?)

    case playing_tracks do
      [] -> nil
      [track] -> track
      _ -> raise "Only one track should play at a time"
    end
  end

  @spec get_tracks() :: [Track.t()]
  defp get_tracks do
    assert %Operation.ReplaceAll{data: tracks} = Dependency.get_value(PlaylistNew)
    tracks
  end
end
