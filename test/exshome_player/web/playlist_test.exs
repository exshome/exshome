defmodule ExshomePlayerTest.Web.PlaylistTest do
  use ExshomeWeb.ConnCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.Dependency
  alias Exshome.Event
  alias ExshomePlayer.Events.PlayerFileEnd
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.{MpvSocket, Playlist}
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  describe "render without dependencies" do
    test "renders fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomePlayer.path(conn, :playlist))
    end
  end

  describe "render with dependencies" do
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

    test "deletes a track", %{view: view, playlist: %Playlist{tracks: tracks}} do
      track = Enum.random(tracks)
      assert track |> Track.url() |> File.exists?()
      assert view |> element("[phx-value-id=#{track.id}][phx-click=delete]") |> render_click()
      refute track |> Track.url() |> File.exists?()
      refute render(view) =~ track.id
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

    defp play_track(view, %Track{id: id}) do
      view |> element("button[phx-value-id=#{id}][phx-click=play]") |> render_click()
      assert view |> element(".playing") |> has_element?()
      assert_receive_app_page_dependency({Playlist, %Playlist{current_id: ^id}})
    end

    defp file_ended do
      Event.broadcast(%PlayerFileEnd{reason: "eof"})
      assert_receive_app_page_dependency({Playlist, %Playlist{}})
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
      close_modal(view)
    end
  end
end
