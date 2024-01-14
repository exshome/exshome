defmodule ExshomePlayerTest.Live.EditLinkModalTest do
  use ExshomeWebTest.ConnCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias ExshomePlayer.Live
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, Playlist}
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  @playlist_page_link "/app/player/playlist"

  setup %{conn: conn} do
    TestMpvServer.server_fixture()
    TestRegistry.start_dependency(MpvSocket, %{})
    start_app_page_dependencies(Live.Playlist)
    {:ok, view, _html} = live(conn, @playlist_page_link)
    assert Dependency.get_value(Playlist) != NotReady
    %{view: view}
  end

  test "creates a link with right data", %{view: view} do
    assert count_playlist_items(view) == 0
    create_valid_track(view)
    assert count_playlist_items(view) == 1
  end

  test "modal has correct return link", %{view: view} do
    refute modal_visible?(view)
    open_modal(view)
    assert modal_visible?(view)

    [cancel_code] =
      view
      |> render()
      |> Floki.attribute("#playlist-modal", "data-cancel")

    assert String.contains?(cancel_code, @playlist_page_link)
  end

  test "fixes an error", %{view: view} do
    assert count_playlist_items(view) == 0
    open_modal(view)

    submit_data(view, %{
      title: "some title #{unique_integer()}",
      path: "some_invalid_data #{unique_integer()}"
    })

    assert modal_visible?(view)

    assert change_form(view, %{path: "some_link#{unique_integer()}.com"}) =~
             "It should start with"

    submit_data(view, %{
      title: "some title #{unique_integer()}",
      path: "#{valid_protocol()}some_link#{unique_integer()}.com"
    })

    assert count_playlist_items(view) == 1
  end

  test "edits a track", %{view: view} do
    flush_messages()
    create_valid_track(view)

    assert_receive_app_page_dependency({Playlist, _})

    view
    |> element("[phx-click='edit']")
    |> render_click()

    updated_link = "#{valid_protocol()}some_link#{unique_integer()}.com"

    submit_data(view, %{
      title: "some title #{unique_integer()}",
      path: updated_link
    })

    assert_receive_app_page_dependency({Playlist, _})

    assert render(view) =~ updated_link
  end

  test "try to edit a file", %{view: view} do
    TestMpvServer.generate_random_tracks(1..1)
    Track.refresh_tracklist()
    [%Track{id: id}] = Dependency.get_value(Playlist)
    {:ok, _view, html} = live_redirect(view, to: "#{@playlist_page_link}/edit-link/#{id}")
    assert html =~ "unable to edit"
  end

  defp open_modal(view) do
    view
    |> element("[phx-click*='add-link']")
    |> render_click()
  end

  defp modal_visible?(view), do: view |> element("#edit_link_modal") |> has_element?()

  defp count_playlist_items(view) do
    view
    |> render()
    |> Floki.find("[phx-click=play]")
    |> length()
  end

  defp submit_data(view, data) do
    view
    |> find_form()
    |> render_submit(%{data: data})
  end

  defp change_form(view, data) do
    view
    |> find_form()
    |> render_change(data)
  end

  defp find_form(view), do: form(view, "form")

  defp valid_protocol, do: Enum.random(["http://", "https://"])

  defp create_valid_track(view) do
    open_modal(view)

    submit_data(view, %{
      title: "some title #{unique_integer()}",
      path: "#{valid_protocol()}some_link#{unique_integer()}.com"
    })
  end
end
