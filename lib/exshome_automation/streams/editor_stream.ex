defmodule ExshomeAutomation.Streams.EditorStream do
  @moduledoc """
  DataStream for workflow editor.
  """

  alias Exshome.Behaviours.EmitterBehaviour

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def emitter_type, do: Exshome.DataStream
end
