defmodule ExshomeWeb.Live.ServicePage.PlayerPage do
  @moduledoc """
  Player page for the application.
  """

  use ExshomeWeb.Live.ServicePageLive,
    prefix: :player,
    view_module: ExshomeWeb.ServicePage.PlayerView,
    actions: [
      index: [],
      preview: [],
      settings: []
    ]
end
