defmodule ExshomeAutomation.Services.WorkflowRegistry do
  @moduledoc """
  Lists available workflows.
  """

  alias Exshome.DataStream.Operation
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Streams.WorkflowStateStream

  use Exshome.Dependency.GenServerDependency,
    name: "automation_workflow_registry",
    subscribe: [
      streams: [WorkflowStateStream]
    ]

  @impl GenServerDependency
  def on_init(%DependencyState{} = state) do
    workflows =
      for %Workflow{} = workflow <- Workflow.list(), into: %{} do
        {workflow.id, workflow}
      end

    update_value(state, fn _ -> workflows end)
  end

  @impl Subscription
  def on_stream(
        %DependencyState{} = state,
        {WorkflowStateStream, %Operation.Delete{data: %Workflow{id: id}}}
      ) do
    update_value(state, &Map.delete(&1, id))
  end

  @impl Subscription
  def on_stream(
        %DependencyState{} = state,
        {WorkflowStateStream, %operation{data: %Workflow{} = workflow}}
      )
      when operation in [Operation.Insert, Operation.Update] do
    update_value(state, &Map.put(&1, workflow.id, workflow))
  end
end
