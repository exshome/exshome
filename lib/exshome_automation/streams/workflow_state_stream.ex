defmodule ExshomeAutomation.Streams.WorkflowStateStream do
  @moduledoc """
  DataStream for workflow state.
  """

  alias Exshome.Behaviours.DataStreamBehaviour
  @behaviour DataStreamBehaviour

  @impl DataStreamBehaviour
  def data_stream_topic({__MODULE__, id}), do: "automation_workflow_state:#{id}"
  def data_stream_topic(__MODULE__), do: "automation_workflow_state"
end
