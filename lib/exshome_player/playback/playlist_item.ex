defmodule ExshomePlayer.Playback.PlaylistItem do
  @moduledoc """
  Structure for working with playlist.
  """
  @keys [:name, :url]
  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          name: String.t(),
          url: String.t()
        }
end
