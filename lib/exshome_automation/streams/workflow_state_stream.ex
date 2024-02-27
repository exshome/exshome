defmodule ExshomeAutomation.Streams.WorkflowStateStream do
  @moduledoc """
  DataStream for workflow state.
  """

  alias Exshome.Behaviours.EmitterBehaviour

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def emitter_type, do: Exshome.DataStream
end
