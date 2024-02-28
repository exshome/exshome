defmodule ExshomePlayer.Streams.TrackStream do
  @moduledoc """
  DataStream for available tracks.
  """

  use Exshome.Behaviours.EmitterBehaviour, type: Exshome.DataStream
end
