defmodule ExshomePlayer.Streams.TrackStream do
  @moduledoc """
  DataStream for available tracks.
  """

  alias Exshome.Behaviours.EmitterBehaviour

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def emitter_type, do: Exshome.DataStream
end
