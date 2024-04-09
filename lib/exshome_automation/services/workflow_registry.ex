defmodule ExshomeAutomation.Services.WorkflowRegistry do
  @moduledoc """
  Lists available workflows.
  """

  alias Exshome.DataStream.Operation
  alias Exshome.Emitter
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Streams.WorkflowStateStream

  use Exshome.Service.DependencyService,
    app: ExshomeAutomation,
    name: "automation_workflow_registry"

  @impl ServiceBehaviour
  def init(%ServiceState{} = state) do
    :ok = Emitter.subscribe(WorkflowStateStream)

    workflows =
      for %Workflow{} = workflow <- Workflow.list(), into: %{} do
        {workflow.id, workflow}
      end

    update_value(state, fn _ -> workflows end)
  end

  @impl DependencyServiceBehaviour
  def handle_stream(
        {WorkflowStateStream, %Operation.Delete{data: %Workflow{id: id}}},
        %ServiceState{} = state
      ) do
    update_value(state, &Map.delete(&1, id))
  end

  def handle_stream(
        {WorkflowStateStream, %operation{data: %Workflow{} = workflow}},
        %ServiceState{} = state
      )
      when operation in [Operation.Insert, Operation.Update] do
    update_value(state, &Map.put(&1, workflow.id, workflow))
  end
end
