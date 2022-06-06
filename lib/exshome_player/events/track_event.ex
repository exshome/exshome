defmodule ExshomePlayer.Events.TrackEvent do
  @moduledoc """
  Fires when something happens to track.
  """
  alias ExshomePlayer.Schemas.Track

  use Exshome.Event, name: "track"

  defstruct [:track, :action]

  @type t() :: %__MODULE__{
          track: Track.t(),
          action: :created | :deleted | :updated
        }
end
