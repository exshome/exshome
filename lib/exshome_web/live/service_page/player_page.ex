defmodule ExshomeWeb.Live.ServicePage.PlayerPage do
  @moduledoc """
  Player page for the application.
  """
  alias Exshome.App.Player.PlayerState

  use ExshomeWeb.Live.ServicePageLive,
    prefix: :player,
    view_module: ExshomeWeb.ServicePage.PlayerView,
    actions: [
      index: [
        {PlayerState.Duration, :duration},
        {PlayerState.Path, :path},
        {PlayerState.Pause, :pause},
        {PlayerState.Position, :position},
        {PlayerState.Title, :title},
        {PlayerState.Volume, :volume}
      ],
      preview: [],
      settings: []
    ]
end
