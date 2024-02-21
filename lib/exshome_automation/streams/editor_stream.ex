defmodule ExshomeAutomation.Streams.EditorStream do
  @moduledoc """
  DataStream for workflow editor.
  """

  alias Exshome.Behaviours.DataStreamBehaviour

  @behaviour DataStreamBehaviour

  @impl DataStreamBehaviour
  def data_stream_topic({__MODULE__, id}), do: "editor_stream:#{id}"
end
