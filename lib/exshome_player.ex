defmodule ExshomePlayer do
  @moduledoc """
  Application related to the player.
  """

  alias ExshomePlayer.Services.MpvServer

  use Exshome.Behaviours.AppBehaviour

  @impl AppBehaviour
  def can_start? do
    case MpvServer.find_mpv_executable() do
      {:ok, _} -> true
      _ -> false
    end
  end
end
