defmodule Exshome.App.Player.PlayerStateEvent do
  @moduledoc """
  Player-related events.
  Usually it is a subset of MpvEvents.
  """

  use Exshome.Event, name: "player_state"
  defstruct [:data]
end
