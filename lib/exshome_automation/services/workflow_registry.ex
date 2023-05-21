defmodule ExshomeAutomation.Services.WorkflowRegistry do
  @moduledoc """
  Lists available workflows.
  """

  alias ExshomeAutomation.Events.WorkflowStateEvent
  alias ExshomeAutomation.Services.Workflow

  use Exshome.Dependency.GenServerDependency,
    name: "automation_workflow_registry",
    subscribe: [
      events: [WorkflowStateEvent]
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
  def handle_event(
        %WorkflowStateEvent{data: %Workflow{id: id}, type: :deleted},
        %DependencyState{} = state
      ) do
    update_value(state, &Map.delete(&1, id))
  end

  @impl Subscription
  def handle_event(
        %WorkflowStateEvent{data: %Workflow{} = workflow, type: type},
        %DependencyState{} = state
      )
      when type in [:created, :updated] do
    update_value(state, &Map.put(&1, workflow.id, workflow))
  end
end
