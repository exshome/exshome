defmodule ExshomePlayer.Streams.TrackStream do
  @moduledoc """
  DataStream for available tracks.
  """

  alias Exshome.Behaviours.DataStreamBehaviour

  @behaviour DataStreamBehaviour

  @impl DataStreamBehaviour
  def data_stream_topic(__MODULE__), do: "tracks"
end
