defmodule ExshomePlayer.Web.Live.Playlist do
  @moduledoc """
  Playlist page.
  """
  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Variables
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  use ExshomeWeb.Live.AppPage,
    icon: "📃",
    dependencies: [{Variables.Path, :current_track}]

  @impl LiveView
  def mount(_params, _session, %Socket{} = socket) do
    socket = assign(socket, :tracks, Playback.tracklist())
    {:ok, socket}
  end

  @impl LiveView
  def handle_event("load_track", %{"url" => url}, %Socket{} = socket) do
    Playback.load_file(url)
    {:noreply, socket}
  end
end
