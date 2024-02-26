defmodule ExshomePlayer.Streams.TrackStream do
  @moduledoc """
  DataStream for available tracks.
  """

  alias Exshome.Behaviours.EmitterBehaviour

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def app, do: ExshomePlayer

  @impl EmitterBehaviour
  def type, do: Exshome.DataStream
end
