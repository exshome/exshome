defmodule ExshomePlayerTest.Live.UploadFileModalTest do
  use ExshomeWebTest.ConnCase, async: true

  import ExshomeTest.Fixtures
  alias ExshomePlayer.Live.Playlist
  alias ExshomePlayer.Services.MpvSocket
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  @playlist_page_link "/app/player/playlist"

  setup %{conn: conn} do
    TestMpvServer.server_fixture()
    TestRegistry.start_service(MpvSocket)
    TestMpvServer.generate_random_tracks(2..10)
    start_app_page_dependencies(Playlist)
    {:ok, view, _html} = live(conn, @playlist_page_link)
    %{view: view}
  end

  test "modal has correct return link", %{view: view} do
    refute has_element?(view, "#upload_files")
    open_file_modal(view)
    assert has_element?(view, "#upload_files")

    [cancel_code] =
      view
      |> render()
      |> Floki.attribute("#playlist-modal", "data-cancel")

    assert String.contains?(cancel_code, @playlist_page_link)
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

  defp open_file_modal(view) do
    view
    |> element("[phx-click='upload-file']")
    |> render_click()
  end

  defp count_playlist_items(view) do
    view
    |> render()
    |> Floki.find("[phx-click=play]")
    |> length()
  end

  defp upload_files(view, files, opts \\ []) do
    open_file_modal(view)
    cancel_uploads = opts[:cancel] || []

    for %{name: name} = file <- files do
      input = file_input(view, "#upload_files", :music, [file])

      if name in cancel_uploads do
        render_upload(input, name)
        %{"ref" => ref} = input.entries |> List.first()

        view
        |> element("[phx-click=cancel-upload][phx-value-ref=#{ref}]")
        |> render_click()
      else
        render_upload(input, name)
      end
    end

    assert view |> form("form") |> render_submit(%{})
  end
end
