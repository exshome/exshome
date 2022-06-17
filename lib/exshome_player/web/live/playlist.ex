defmodule ExshomePlayer.Web.Live.Playlist do
  @moduledoc """
  Playlist page.
  """
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playlist

  use ExshomeWeb.Live.AppPage,
    icon: "📃",
    dependencies: [{Playlist, :playlist}]

  @impl LiveView
  def handle_event("play", %{"id" => id}, %Socket{} = socket) do
    Playlist.play(id)
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, %Socket{} = socket) do
    id
    |> Track.get!()
    |> Track.delete!()

    {:noreply, socket}
  end

  def handle_event("open_file_modal", _, %Socket{} = socket) do
    {:noreply, open_modal(socket, ExshomePlayer.Web.Live.UploadFileModal)}
  end

  def handle_event("open_new_link_modal", _, %Socket{} = socket) do
    {:noreply, open_modal(socket, ExshomePlayer.Web.Live.EditLinkModal)}
  end
end
