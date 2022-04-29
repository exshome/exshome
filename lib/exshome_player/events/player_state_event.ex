defmodule ExshomePlayer.Events.PlayerStateEvent do
  @moduledoc """
  Player-related events.
  Usually it is a subset of MpvEvents.
  """

  use Exshome.Event, name: "player_state"
  defstruct [:data, :type]

  @type t() :: %__MODULE__{
          type: String.t(),
          data: map()
        }
end
