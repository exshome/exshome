defmodule ExshomePlayer.Events.PlayerFileEnd do
  @moduledoc """
  Shows that file has ended.
  """

  use Exshome.Event, name: "player_file_end"
  defstruct [:reason]

  @type t() :: %__MODULE__{
          reason: String.t()
        }
end
