defmodule ExshomeWeb.Live.App.Player.Preview do
  @moduledoc """
  Player preview widget.
  """
  alias Exshome.App.Player.PlayerState

  use ExshomeWeb.Live.AppPage,
    dependencies: [
      {PlayerState.Pause, :pause},
      {PlayerState.Title, :title}
    ]
end
