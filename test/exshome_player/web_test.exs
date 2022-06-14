defmodule ExshomePlayerTest.WebTest do
  use ExshomeWeb.ConnCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.Dependency
  alias Exshome.Event
  alias ExshomePlayer.Events.PlayerFileEnd
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, Playback, PlayerState, Playlist}
  alias ExshomePlayer.Variables
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  describe "player page index without dependencies" do
    test "renders fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomePlayer.path(conn, :index))
    end
  end

  describe "player page index with dependencies" do
    setup %{conn: conn} do
      TestMpvServer.server_fixture()
      TestRegistry.start_dependency(MpvSocket, %{})
      TestRegistry.start_dependency(PlayerState, %{})
      view = live_with_dependencies(conn, ExshomePlayer, :index)
      %{view: view}
    end

    test "updates volume", %{view: view} do
      volume_selector = "[name=volume]"
      volume = unique_integer()
      view |> element(volume_selector) |> render_change(%{volume: volume})
      assert_receive_dependency({Variables.Volume, volume})
      assert get_value(view, volume_selector) == Integer.to_string(volume)
    end

    test "updates position", %{view: view} do
      position_selector = "[name=position]"
      position = unique_integer()
      view |> element(position_selector) |> render_change(%{position: position})
      assert_receive_dependency({Variables.Position, position})
      assert get_value(view, position_selector) == Integer.to_string(position)
    end

    test "updates pause state", %{view: view} do
      random_file = "some_file#{unique_integer()}"
      Playback.load_url(random_file)

      assert_receive_app_page_dependency({Variables.Pause, false})
      assert view |> element("[phx-click=pause]") |> render_click()
      assert_receive_app_page_dependency({Variables.Pause, true})
      assert view |> element("[phx-click=play]") |> render_click()
      assert_receive_app_page_dependency({Variables.Pause, false})
      assert view |> element("[phx-click=pause]") |> render_click()
      assert_receive_app_page_dependency({Variables.Pause, true})
    end

    test "navigates through playlist", %{view: view} do
      TestMpvServer.generate_random_tracks(2..10)
      TestRegistry.start_dependency(Playlist)

      %Playlist{
        tracks: [
          %Track{id: first_id},
          %Track{id: second_id} | _
        ]
      } = Dependency.get_value(Playlist)

      Playlist.play(first_id)
      assert %Playlist{current_id: ^first_id} = Dependency.get_value(Playlist)
      assert view |> element("[phx-click=next_track]") |> render_click()
      assert %Playlist{current_id: ^second_id} = Dependency.get_value(Playlist)
      assert view |> element("[phx-click=previous_track]") |> render_click()
      assert %Playlist{current_id: ^first_id} = Dependency.get_value(Playlist)
    end
  end

  describe "player page preview" do
    test "renders without dependencies", %{conn: conn} do
      assert live_preview(conn, ExshomePlayer)
    end
  end

  describe "playlist page without dependencies" do
    test "renders fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomePlayer.path(conn, :playlist))
    end
  end

  describe "playlist page with dependencies" do
    setup %{conn: conn} do
      TestMpvServer.server_fixture()
      TestRegistry.start_dependency(MpvSocket, %{})
      TestMpvServer.generate_random_tracks(2..10)
      view = live_with_dependencies(conn, ExshomePlayer, :playlist)
      %Playlist{} = playlist = Dependency.get_value(Playlist)
      %{view: view, playlist: playlist}
    end

    test "plays a track", %{view: view, playlist: %Playlist{tracks: tracks}} do
      refute view |> element(".playing") |> has_element?()
      track = List.first(tracks)
      play_track(view, track)
      assert view |> element(".playing") |> has_element?()
    end

    test "moves to another track", %{view: view, playlist: %Playlist{tracks: tracks}} do
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

    defp play_track(view, %Track{id: id}) do
      view |> element("button[phx-value-id=#{id}][phx-click=play]") |> render_click()
      assert view |> element(".playing") |> has_element?()
      assert_receive_app_page_dependency({Playlist, %Playlist{current_id: ^id}})
    end

    defp file_ended do
      Event.broadcast(%PlayerFileEnd{reason: "eof"})
      assert_receive_app_page_dependency({Playlist, %Playlist{}})
    end
  end

  defp get_value(view, selector) do
    [value] = view |> render() |> Floki.attribute(selector, "value")
    value
  end
end
