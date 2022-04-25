defmodule ExshomeWeb.Live.PlayerApp.Index do
  @moduledoc """
  Main player page.
  """
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  alias Exshome.App.Player.{Playback, PlayerState}

  use ExshomeWeb.Live.AppPage,
    icon: "🎵",
    dependencies: [
      {PlayerState.Duration, :duration},
      {PlayerState.Pause, :pause},
      {PlayerState.Position, :position},
      {PlayerState.Title, :title},
      {PlayerState.Volume, :volume}
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
end
