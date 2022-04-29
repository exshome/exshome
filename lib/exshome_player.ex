defmodule ExshomePlayer do
  @moduledoc """
  Application related to the player.
  """

  alias ExshomePlayer.Web.Live

  use ExshomeWeb.Live.App,
    pages: [Live.Index],
    prefix: :player,
    preview: Live.Preview
end
