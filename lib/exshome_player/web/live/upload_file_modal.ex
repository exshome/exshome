defmodule ExshomePlayer.Web.Live.UploadFileModal do
  @moduledoc """
  Modal for uploading files.
  """
  use ExshomeWeb.Live.AppPage, dependencies: []

  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.MpvServer

  @impl LiveView
  def mount(_params, _session, %Socket{} = socket) do
    {:ok, allow_upload(socket, :music, accept: ~w(.mp3), max_entries: 10)}
  end

  @impl LiveView
  def handle_event("validate", _params, %Socket{} = socket) do
    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, %Socket{} = socket) do
    {:noreply, cancel_upload(socket, :music, ref)}
  end

  @impl LiveView
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

    {:noreply, socket}
  end

  @spec sanitize_file_name(String.t(), String.t()) :: String.t()
  defp sanitize_file_name(music_folder, file_name) do
    extension = Path.extname(file_name)
    name = Path.basename(file_name, extension)
    name = Regex.replace(~r"\W+", name, "_")
    file_name = "#{name}#{extension}"

    if file_name in File.ls!(music_folder) do
      sanitize_file_name(music_folder, "#{name}_#{Ecto.UUID.generate()}#{extension}")
    else
      file_name
    end
  end
end
