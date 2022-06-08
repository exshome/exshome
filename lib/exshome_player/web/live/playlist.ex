defmodule ExshomePlayer.Web.Live.Playlist do
  @moduledoc """
  Playlist page.
  """
  alias ExshomePlayer.Services.Playlist
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  use ExshomeWeb.Live.AppPage,
    icon: "📃",
    dependencies: [{Playlist, :playlist}]

  @impl LiveView
  def handle_event("play", %{"id" => id}, %Socket{} = socket) do
    Playlist.play(id)
    {:noreply, socket}
  end

  def handle_event("open_file_modal", _, %Socket{} = socket) do
    {:noreply, open_modal(socket, ExshomePlayer.Web.Live.UploadFileModal)}
  end
end
