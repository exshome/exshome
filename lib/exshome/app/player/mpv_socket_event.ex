defmodule Exshome.App.Player.MpvSocketEvent do
  @moduledoc """
  Mpv socket events.
  """

  use Exshome.Event, name: "mpv_socket"
  defstruct [:data]
end
