defmodule Exshome.App.Player.PlayerStateEvent do
  @moduledoc """
  Player-related events.
  Usually it is a subset of MpvEvents.
  """

  use Exshome.Event, name: "player_state"
  defstruct [:data]

  @type t() :: %__MODULE__{
          data: map()
        }
end
