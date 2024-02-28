defmodule ExshomePlayer.Events.PlayerStateEvent do
  @moduledoc """
  Player-related events.
  Usually it is a subset of MpvEvents.
  """

  use Exshome.Behaviours.EmitterBehaviour, type: Exshome.Event
end
