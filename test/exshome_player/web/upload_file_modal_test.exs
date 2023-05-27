defmodule ExshomePlayerTest.Web.UploadFileModalTest do
  use ExshomeWebTest.ConnCase, async: true

  import ExshomeTest.Fixtures
  alias ExshomePlayer.Services.MpvSocket
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  setup %{conn: conn} do
    TestMpvServer.server_fixture()
    TestRegistry.start_dependency(MpvSocket, %{})
    TestMpvServer.generate_random_tracks(2..10)
    view = live_with_dependencies(conn, ExshomePlayer, "playlist")
    %{view: view}
  end

  test "uploads a new track", %{view: view} do
    file_name = "test_#{unique_integer()}.mp3"
    playlist_items_number = count_playlist_items(view)

    upload_files(view, [%{name: file_name, content: "data"}])

    assert render(view) =~ file_name
    assert count_playlist_items(view) == playlist_items_number + 1
  end

  test "uploads the same track", %{view: view} do
    file_name = "test_#{unique_integer()}.mp3"
    playlist_items_number = count_playlist_items(view)

    upload_files(view, [%{name: file_name, content: "data"}])

    assert render(view) =~ file_name
    assert count_playlist_items(view) == playlist_items_number + 1

    upload_files(view, [%{name: file_name, content: "data"}])
    assert count_playlist_items(view) == playlist_items_number + 2
  end

  test "uploads multiple tracks", %{view: view} do
    file_name_1 = "test_#{unique_integer()}.mp3"
    file_name_2 = "test_#{unique_integer()}.mp3"
    playlist_items_number = count_playlist_items(view)

    upload_files(view, [
      %{name: file_name_1, content: "data1"},
      %{name: file_name_2, content: "data2"}
    ])

    assert render(view) =~ file_name_1
    assert render(view) =~ file_name_2
    assert count_playlist_items(view) == playlist_items_number + 2
  end

  test "cancels upload", %{view: view} do
    file_name_1 = "test_#{unique_integer()}.mp3"
    file_name_2 = "test_#{unique_integer()}.mp3"
    playlist_items_number = count_playlist_items(view)

    upload_files(
      view,
      [
        %{name: file_name_1, content: "data1"},
        %{name: file_name_2, content: "data2"}
      ],
      cancel: [file_name_2]
    )

    assert render(view) =~ file_name_1
    refute render(view) =~ file_name_2
    assert count_playlist_items(view) == playlist_items_number + 1
  end

  test "opens and closes a modal", %{view: view} do
    refute view |> element("#upload_files") |> has_element?()
    open_file_modal(view)
    assert view |> element("#upload_files") |> has_element?()
    close_modal(view)
    refute view |> element("#upload_files") |> has_element?()
  end

  defp open_file_modal(view) do
    view
    |> element("[phx-click=open_file_modal]")
    |> render_click()
  end

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

  defp upload_files(view, files, opts \\ []) do
    open_file_modal(view)
    modal_view = find_live_child(view, "modal-data")
    cancel_uploads = opts[:cancel] || []

    for %{name: name} = file <- files do
      input = file_input(modal_view, "#upload_files", :music, [file])

      if name in cancel_uploads do
        render_upload(input, name)
        %{"ref" => ref} = input.entries |> List.first()

        modal_view
        |> element("[phx-click=cancel-upload][phx-value-ref=#{ref}]")
        |> render_click()
      else
        render_upload(input, name)
      end
    end

    assert modal_view |> form("form") |> render_submit(%{})
  end
end
