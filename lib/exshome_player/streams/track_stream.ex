defmodule ExshomePlayer.Streams.TrackStream do
  @moduledoc """
  DataStream for available tracks.
  """
  alias ExshomePlayer.Schemas.Track
  use Exshome.DataStream, "tracks"

  @impl DataStream
  def handle_get_value, do: Track.list()
end
