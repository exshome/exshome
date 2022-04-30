defmodule ExshomePlayerTest.WebTest do
  use ExshomeWeb.ConnCase, async: true
  @moduletag :mpv_test_folder

  alias Exshome.Dependency
  import ExshomeTest.Fixtures
  alias ExshomePlayer.Services.{MpvSocket, Playback, PlayerState}
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
      assert Dependency.subscribe(Variables.Pause) != Dependency.NotReady

      random_file = "some_file#{unique_integer()}"
      Playback.load_file(random_file)

      assert_receive_dependency({Variables.Pause, false})
      assert view |> element("[phx-click=pause]") |> render_click()
      assert_receive_dependency({Variables.Pause, true})
      assert view |> element("[phx-click=play]") |> render_click()
      assert_receive_dependency({Variables.Pause, false})
      assert view |> element("[phx-click=pause]") |> render_click()
      assert_receive_dependency({Variables.Pause, true})
    end
  end

  describe "player page preview" do
    test "renders without dependencies", %{conn: conn} do
      assert live_preview(conn, ExshomePlayer)
    end
  end

  defp get_value(view, selector) do
    [value] = view |> render() |> Floki.attribute(selector, "value")
    value
  end
end
