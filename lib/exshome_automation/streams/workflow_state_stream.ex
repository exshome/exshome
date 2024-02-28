defmodule ExshomeAutomation.Streams.WorkflowStateStream do
  @moduledoc """
  DataStream for workflow state.
  """

  use Exshome.Behaviours.EmitterBehaviour, type: Exshome.DataStream
end
