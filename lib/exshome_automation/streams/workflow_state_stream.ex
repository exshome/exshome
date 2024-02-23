defmodule ExshomeAutomation.Streams.WorkflowStateStream do
  @moduledoc """
  DataStream for workflow state.
  """

  alias Exshome.Behaviours.DataStreamBehaviour

  @behaviour DataStreamBehaviour

  @impl DataStreamBehaviour
  def data_stream_topic, do: "exshome_automation:automation_workflow_state"
end
