defmodule ExshomePlayer do
  @moduledoc """
  Application related to the player.
  """

  alias ExshomePlayer.Services.MpvServer
  alias ExshomePlayer.Web.Live

  use ExshomeWeb.App,
    pages: [Live.Player, Live.Playlist],
    prefix: "player",
    preview: Live.Preview

  @impl App
  def can_start? do
    case MpvServer.find_mpv_executable() do
      {:ok, _} -> true
      _ -> false
    end
  end

  use Exshome.Behaviours.AppBehaviour

  @impl AppBehaviour
  def app_settings,
    do: %AppBehaviour{
      pages: [Live.Player, Live.Playlist],
      prefix: "player",
      preview: Live.Preview
    }
end
