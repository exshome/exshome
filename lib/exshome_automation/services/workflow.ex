defmodule ExshomeAutomation.Services.Workflow do
  @moduledoc """
  A module for automation workflows.
  """

  alias Exshome.Event
  alias Exshome.SystemRegistry
  alias ExshomeAutomation.Events.WorkflowStateEvent
  alias ExshomeAutomation.Services.Workflow.Schema
  alias ExshomeAutomation.Services.Workflow.WorkflowSupervisor

  defstruct [:active, :id, :name]

  @type t() :: %__MODULE__{
          active: boolean(),
          id: String.t(),
          name: String.t()
        }

  use Exshome.Dependency.GenServerDependency,
    name: "automation_workflow",
    child_module: WorkflowSupervisor

  @impl GenServerDependency
  def on_init(%DependencyState{} = state) do
    {__MODULE__, id} = state.dependency
    %Schema{name: name} = Schema.get!(id)

    value = %__MODULE__{
      active: true,
      id: id,
      name: name
    }

    register_workflow_data(value)
    update_value(state, fn _ -> value end)
  end

  @spec list() :: [t()]
  def list, do: SystemRegistry.list(__MODULE__)

  @spec register_workflow_data(t()) :: :ok
  defp register_workflow_data(%__MODULE__{} = workflow_data) do
    :ok = SystemRegistry.register!(__MODULE__, workflow_data.id, workflow_data)
    broadcast_event(%WorkflowStateEvent{data: workflow_data, type: :created})
  end

  defp broadcast_event(%WorkflowStateEvent{} = event) do
    :ok = Event.broadcast(event)
    :ok = Event.broadcast(event, event.data.id)
  end
end
