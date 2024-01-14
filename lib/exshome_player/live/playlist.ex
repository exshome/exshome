defmodule ExshomePlayer.Live.Playlist do
  @moduledoc """
  Playlist page.
  """
  alias ExshomePlayer.Live
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playlist

  use ExshomeWeb.Live.AppPage,
    dependencies: [{Playlist, :playlist}]

  @impl LiveView
  def handle_params(params, _, %Socket{} = socket) do
    modal = get_modal(socket.assigns.live_action, params)
    {:noreply, assign(socket, modal: modal)}
  end

  defp get_modal(:add_link, _), do: %{module: Live.EditLinkModal, params: %{track_id: :new}}

  defp get_modal(:edit_link, %{"id" => id}),
    do: %{module: Live.EditLinkModal, params: %{track_id: id}}

  defp get_modal(:upload_file, _), do: %{module: Live.UploadFileModal, params: %{}}
  defp get_modal(_, _), do: nil

  @impl LiveView
  def handle_event("play", %{"id" => id}, %Socket{} = socket) do
    Playlist.play(id)
    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("upload-file", _, %Socket{} = socket) do
    {:noreply, push_patch(socket, to: ~p"/app/player/playlist/upload-file")}
  end

  @impl LiveView
  def handle_event("edit", %{"id" => id}, %Socket{} = socket) do
    {:noreply, push_patch(socket, to: ~p"/app/player/playlist/edit-link/#{id}")}
  end

  @impl LiveView
  def handle_event("add-link", _, %Socket{} = socket) do
    {:noreply, push_patch(socket, to: ~p"/app/player/playlist/add-link")}
  end

  @impl LiveView
  def handle_event("delete", %{"id" => id}, %Socket{} = socket) do
    id
    |> Track.get!()
    |> Track.delete!()

    {:noreply, socket}
  end
end
