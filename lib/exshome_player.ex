defmodule ExshomePlayer do
  @moduledoc """
  Application related to the player.
  """

  alias ExshomePlayer.Services.MpvServer
  alias ExshomePlayer.Web.Live

  use Exshome.Behaviours.AppBehaviour,
    pages: [
      {Live.Player, []},
      {Live.Playlist, []}
    ],
    prefix: "player",
    preview: Live.Preview,
    template_root: "./exshome_player/web/templates"

  @impl AppBehaviour
  def can_start? do
    case MpvServer.find_mpv_executable() do
      {:ok, _} -> true
      _ -> false
    end
  end
end
