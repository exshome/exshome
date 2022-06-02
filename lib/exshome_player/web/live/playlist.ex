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
end
