defmodule ExshomePlayer.Events.MpvEvent do
  @moduledoc """
  Mpv socket events.
  """

  use Exshome.Behaviours.EmitterBehaviour, type: Exshome.Event
end
