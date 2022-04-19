defmodule ExshomeWeb.Live.ServicePage.PlayerPage do
  @moduledoc """
  Player page for the application.
  """
  alias Exshome.App.Player.{Playback, PlayerState}

  use ExshomeWeb.Live.ServicePageLive,
    prefix: :player,
    view_module: ExshomeWeb.ServicePage.PlayerView,
    actions: [
      index: [
        {PlayerState.Duration, :duration},
        {PlayerState.Pause, :pause},
        {PlayerState.Position, :position},
        {PlayerState.Title, :title},
        {PlayerState.Volume, :volume}
      ],
      preview: [
        {PlayerState.Pause, :pause},
        {PlayerState.Title, :title}
      ],
      settings: []
    ]

  @impl ServicePageLive
  def handle_event("set_volume", %{"volume" => volume}, %Socket{} = socket) do
    volume
    |> String.to_integer()
    |> Playback.set_volume()

    {:noreply, socket}
  end

  @impl ServicePageLive
  def handle_event("set_position", %{"position" => position}, %Socket{} = socket) do
    position
    |> String.to_integer()
    |> Playback.seek()

    {:noreply, socket}
  end

  @impl ServicePageLive
  def handle_event("play", _, %Socket{} = socket) do
    Playback.play()

    {:noreply, socket}
  end

  @impl ServicePageLive
  def handle_event("pause", _, %Socket{} = socket) do
    Playback.pause()

    {:noreply, socket}
  end
end
