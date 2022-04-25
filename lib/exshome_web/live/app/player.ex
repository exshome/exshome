defmodule ExshomeWeb.Live.PlayerApp do
  @moduledoc """
  Live player applicaton.
  """

  alias __MODULE__

  use ExshomeWeb.Live.App,
    pages: [PlayerApp.Index],
    prefix: :player,
    preview: PlayerApp.Preview,
    view_module: ExshomeWeb.App.PlayerView
end
