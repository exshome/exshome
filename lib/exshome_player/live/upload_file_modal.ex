defmodule ExshomePlayer.Live.UploadFileModal do
  @moduledoc """
  Modal for uploading files.
  """
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.MpvServer
  alias Phoenix.LiveView.Socket

  use ExshomeWeb, :live_component

  @impl LiveComponent
  def mount(%Socket{} = socket) do
    {:ok, allow_upload(socket, :music, accept: ~w(.mp3), max_entries: 10)}
  end

  @impl LiveComponent
  def handle_event("validate", _params, %Socket{} = socket) do
    {:noreply, socket}
  end

  @impl LiveComponent
  def handle_event("cancel-upload", %{"ref" => ref}, %Socket{} = socket) do
    {:noreply, cancel_upload(socket, :music, ref)}
  end

  @impl LiveComponent
  def handle_event("save", _params, %Socket{} = socket) do
    files =
      consume_uploaded_entries(socket, :music, fn %{path: path}, entry ->
        music_folder = MpvServer.music_folder()

        file_name = sanitize_file_name(music_folder, entry.client_name)
        dest = Path.join(music_folder, file_name)
        File.cp!(path, dest)
        {:ok, path}
      end)

    if length(files) > 0 do
      Track.refresh_tracklist()
    end

    {:noreply, push_patch(socket, to: ~p"/app/player/playlist")}
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"

  @spec sanitize_file_name(String.t(), String.t()) :: String.t()
  defp sanitize_file_name(music_folder, file_name) do
    extension = Path.extname(file_name)
    name = Path.basename(file_name, extension)
    name = Regex.replace(~r"\W+", name, "_")
    file_name = "#{name}#{extension}"

    if file_name in File.ls!(music_folder) do
      sanitize_file_name(music_folder, "#{name}_1#{extension}")
    else
      file_name
    end
  end
end
