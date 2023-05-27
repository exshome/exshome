defmodule ExshomePlayerTest.Web.PlaylistTest do
  use ExshomeWebTest.ConnCase, async: true

  alias Exshome.Dependency
  alias Exshome.Event
  alias ExshomePlayer.Events.PlayerFileEnd
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, Playlist}
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  describe "render without dependencies" do
    test "renders fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomePlayer.path(conn, "playlist"))
    end
  end

  describe "render with dependencies" do
    setup %{conn: conn} do
      TestMpvServer.server_fixture()
      TestRegistry.start_dependency(MpvSocket, %{})
      TestMpvServer.generate_random_tracks(3..10)
      Track.refresh_tracklist()
      view = live_with_dependencies(conn, ExshomePlayer, "playlist")
      tracks = Dependency.subscribe(Playlist)
      %{view: view, tracks: tracks}
    end

    test "plays a track", %{view: view, tracks: tracks} do
      refute view |> element(".playing") |> has_element?()
      track = List.first(tracks)
      play_track(view, track)
      assert view |> element(".playing") |> has_element?()
    end

    test "moves to another track", %{view: view, tracks: tracks} do
      first_track = List.first(tracks)
      play_track(view, first_track)
      assert view |> element("[phx-value-id=#{first_track.id}].playing") |> has_element?()

      second_track = Enum.at(tracks, 1)
      file_ended()
      assert view |> element("[phx-value-id=#{second_track.id}].playing") |> has_element?()

      last_track = List.last(tracks)
      play_track(view, last_track)
      assert view |> element("[phx-value-id=#{last_track.id}].playing") |> has_element?()
      file_ended()
      refute view |> element(".playing") |> has_element?()
    end

    test "deletes a track", %{view: view, tracks: tracks} do
      track = Enum.random(tracks)
      assert track |> Track.url() |> File.exists?()
      assert view |> element("[phx-value-id=#{track.id}][phx-click=delete]") |> render_click()
      refute track |> Track.url() |> File.exists?()
      refute render(view) =~ track.id
    end

    defp play_track(view, %Track{id: id}) do
      flush_messages()
      view |> element("button[phx-value-id=#{id}][phx-click=play]") |> render_click()
      assert_receive_app_page_dependency({Playlist, _})
      assert view |> element(".playing") |> has_element?()
    end

    defp file_ended do
      Event.broadcast(%PlayerFileEnd{reason: "eof"})
      assert_receive_app_page_dependency({Playlist, _})
    end
  end
end
