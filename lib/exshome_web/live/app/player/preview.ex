defmodule ExshomeWeb.Live.PlayerApp.Preview do
  @moduledoc """
  Player preview widget.
  """
  alias ExshomePlayer.PlayerState

  use ExshomeWeb.Live.AppPage,
    dependencies: [
      {PlayerState.Pause, :pause},
      {PlayerState.Title, :title}
    ]
end
