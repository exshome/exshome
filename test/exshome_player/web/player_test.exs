defmodule ExshomePlayerTest.Web.PlayerTest do
  use ExshomeWeb.ConnCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.Dependency
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, Playback, PlayerState, Playlist}
  alias ExshomePlayer.Variables
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  describe "render without dependencies" do
    test "renders fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomePlayer.path(conn, :player))
    end
  end

  describe "render with dependencies" do
    setup %{conn: conn} do
      TestMpvServer.server_fixture()
      TestRegistry.start_dependency(MpvSocket, %{})
      TestRegistry.start_dependency(PlayerState, %{})
      view = live_with_dependencies(conn, ExshomePlayer, :player)
      %{view: view}
    end

    test "updates volume", %{view: view} do
      volume_selector = "[name=volume]"
      volume = Enum.random(0..100)
      view |> element(volume_selector) |> render_change(%{volume: volume})
      assert_receive_dependency({Variables.Volume, volume})
      assert get_value(view, volume_selector) == Integer.to_string(volume)
    end

    test "updates position", %{view: view} do
      duration = unique_integer()
      Dependency.broadcast_value(PlayerState, %PlayerState{duration: duration})
      position = Enum.random(0..duration)
      position_selector = "[name=position]"
      view |> element(position_selector) |> render_change(%{position: position})
      assert_receive_app_page_dependency({Variables.Position, position})
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
end
