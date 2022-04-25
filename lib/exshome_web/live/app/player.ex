defmodule ExshomeWeb.Live.App.Player do
  @moduledoc """
  Live player applicaton.
  """

  alias __MODULE__

  use ExshomeWeb.Live.App,
    pages: [Player.Index],
    prefix: :player,
    preview: Player.Preview,
    view_module: ExshomeWeb.App.PlayerView
end
