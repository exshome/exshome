defmodule ExshomePlayer.Web.Live.Index do
  @moduledoc """
  Main player page.
  """
  alias ExshomePlayer.Services.{Playback, Playlist}
  alias ExshomePlayer.Variables
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  use ExshomeWeb.Live.AppPage,
    icon: "🎵",
    dependencies: [
      {Variables.Duration, :duration},
      {Variables.Pause, :pause},
      {Variables.Position, :position},
      {Variables.Title, :title},
      {Variables.Volume, :volume}
    ]

  @impl LiveView
  def handle_event("set_volume", %{"volume" => volume}, %Socket{} = socket) do
    volume
    |> String.to_integer()
    |> Playback.set_volume()

    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("set_position", %{"position" => position}, %Socket{} = socket) do
    position
    |> String.to_integer()
    |> Playback.seek()

    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("play", _, %Socket{} = socket) do
    Playback.play()

    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("pause", _, %Socket{} = socket) do
    Playback.pause()

    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("previous_track", _, %Socket{} = socket) do
    Playlist.previous()

    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("next_track", _, %Socket{} = socket) do
    Playlist.next()

    {:noreply, socket}
  end
end
