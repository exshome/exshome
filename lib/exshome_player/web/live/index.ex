defmodule ExshomePlayer.Web.Live.Index do
  @moduledoc """
  Main player page.
  """
  alias Exshome.Variable
  alias ExshomePlayer.Services.Playlist
  alias ExshomePlayer.Variables

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
    value = String.to_integer(volume)
    Variable.set_value!(Variables.Volume, value)

    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("set_position", %{"position" => position}, %Socket{} = socket) do
    value = String.to_integer(position)
    Variable.set_value!(Variables.Position, value)

    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("play", _, %Socket{} = socket) do
    Variable.set_value!(Variables.Pause, false)

    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("pause", _, %Socket{} = socket) do
    Variable.set_value!(Variables.Pause, true)

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
