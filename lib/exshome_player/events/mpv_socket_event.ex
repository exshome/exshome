defmodule ExshomePlayer.Events.MpvSocketEvent do
  @moduledoc """
  Mpv socket events.
  """

  use Exshome.Event, name: "mpv_socket"
  defstruct [:data, :type]

  @type t() :: %__MODULE__{
          data: map(),
          type: String.t()
        }
end
