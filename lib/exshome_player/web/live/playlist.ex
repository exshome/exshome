defmodule ExshomePlayer.Web.Live.Playlist do
  @moduledoc """
  Playlist page.
  """
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playlist
  alias ExshomePlayer.Streams.PlaylistStream

  use ExshomeWeb.Live.AppPage,
    icon: "hero-list-bullet-mini",
    streams: [{PlaylistStream, :playlist}]

  @impl LiveView
  def handle_event("play", %{"id" => id}, %Socket{} = socket) do
    Playlist.play(id)
    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("delete", %{"id" => id}, %Socket{} = socket) do
    id
    |> Track.get!()
    |> Track.delete!()

    {:noreply, socket}
  end

  def handle_event("edit", %{"id" => id}, %Socket{} = socket) do
    {:noreply, open_modal(socket, ExshomePlayer.Web.Live.EditLinkModal, %{"track_id" => id})}
  end

  @impl LiveView
  def handle_event("open_file_modal", _, %Socket{} = socket) do
    {:noreply, open_modal(socket, ExshomePlayer.Web.Live.UploadFileModal)}
  end

  @impl LiveView
  def handle_event("open_new_link_modal", _, %Socket{} = socket) do
    {:noreply, open_modal(socket, ExshomePlayer.Web.Live.EditLinkModal)}
  end
end
