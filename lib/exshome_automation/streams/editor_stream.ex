defmodule ExshomeAutomation.Streams.EditorStream do
  @moduledoc """
  DataStream for workflow editor.
  """

  alias Exshome.Behaviours.DataStreamBehaviour

  @behaviour DataStreamBehaviour

  @impl DataStreamBehaviour
  def data_stream_topic, do: "exshome_automation:editor_stream"
end
