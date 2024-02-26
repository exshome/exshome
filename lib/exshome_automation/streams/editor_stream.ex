defmodule ExshomeAutomation.Streams.EditorStream do
  @moduledoc """
  DataStream for workflow editor.
  """

  alias Exshome.Behaviours.EmitterBehaviour

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def app, do: ExshomeAutomation

  @impl EmitterBehaviour
  def type, do: Exshome.DataStream
end
