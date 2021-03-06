defmodule ExshomePlayerTest.Web.EditLinkModalTest do
  use ExshomeWeb.ConnCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.Dependency
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, Playlist}
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  setup %{conn: conn} do
    TestMpvServer.server_fixture()
    TestRegistry.start_dependency(MpvSocket, %{})
    view = live_with_dependencies(conn, ExshomePlayer, :playlist)
    %Playlist{} = Dependency.get_value(Playlist)
    %{view: view}
  end

  test "opens and closes a modal", %{view: view} do
    refute modal_visible?(view)
    open_modal(view)
    assert modal_visible?(view)
    close_modal(view)
    refute modal_visible?(view)
  end

  test "creates a link with right data", %{view: view} do
    assert count_playlist_items(view) == 0
    create_valid_track(view)
    assert count_playlist_items(view) == 1
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
    create_valid_track(view)

    view
    |> element("[phx-click=edit]")
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
    %Playlist{tracks: [%Track{id: id}]} = Dependency.get_value(Playlist)
    assert render_click(view, "edit", %{id: id}) =~ "unable to edit"
  end

  defp open_modal(view) do
    view
    |> element("[phx-click=open_new_link_modal]")
    |> render_click()
  end

  defp modal_visible?(view), do: view |> element("#edit_link_modal") |> has_element?()

  defp count_playlist_items(view) do
    view
    |> render()
    |> Floki.find("[phx-click=play]")
    |> length()
  end

  defp close_modal(view) do
    assert view
           |> element("button[phx-click='modal:close']")
           |> render_click()
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

  defp find_form(view), do: view |> find_live_child("modal-data") |> form("form")

  defp valid_protocol, do: Enum.random(["http://", "https://"])

  defp create_valid_track(view) do
    open_modal(view)

    submit_data(view, %{
      title: "some title #{unique_integer()}",
      path: "#{valid_protocol()}some_link#{unique_integer()}.com"
    })
  end
end
