defmodule ExshomePlayer.Web.Live.Preview do
  @moduledoc """
  Player preview widget.
  """
  alias ExshomePlayer.Variables

  use ExshomeWeb.Live.AppPage,
    dependencies: [
      {Variables.Pause, :pause},
      {Variables.Title, :title}
    ]
end
