defmodule ExshomeAutomation.Streams.WorkflowStateStream do
  @moduledoc """
  DataStream for workflow state.
  """

  alias Exshome.Behaviours.EmitterBehaviour

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def app, do: ExshomeAutomation

  @impl EmitterBehaviour
  def type, do: Exshome.DataStream
end
