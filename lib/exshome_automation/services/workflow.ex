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

    value =
      id
      |> Schema.get!()
      |> schema_to_workflow_data()

    register_workflow_data(value)
    update_value(state, fn _ -> value end)
  end

  @impl GenServerDependency
  def handle_stop(_reason, %DependencyState{} = state) do
    :ok = remove_workflow_data(state.value)
    state
  end

  @spec list() :: [t()]
  def list, do: SystemRegistry.list(__MODULE__)

  @spec create!() :: :ok
  def create! do
    %Schema{id: id} = Schema.create!()
    WorkflowSupervisor.start_child_with_id(id)
  end

  @spec delete!(String.t()) :: :ok
  def delete!(id) when is_binary(id) do
    id
    |> Schema.get!()
    |> Schema.delete!()

    :ok = WorkflowSupervisor.terminate_child_with_id(id)
  end

  defp schema_to_workflow_data(%Schema{id: id, name: name}) do
    %__MODULE__{
      active: true,
      id: id,
      name: name
    }
  end

  @spec register_workflow_data(t()) :: :ok
  defp register_workflow_data(%__MODULE__{} = workflow_data) do
    :ok = SystemRegistry.register!(__MODULE__, workflow_data.id, workflow_data)
    broadcast_event(%WorkflowStateEvent{data: workflow_data, type: :created})
  end

  @spec remove_workflow_data(t()) :: :ok
  def remove_workflow_data(%__MODULE__{} = workflow_data) do
    :ok = SystemRegistry.remove!(__MODULE__, workflow_data.id)
    broadcast_event(%WorkflowStateEvent{data: workflow_data, type: :deleted})
  end

  defp broadcast_event(%WorkflowStateEvent{} = event) do
    :ok = Event.broadcast(event)
    :ok = Event.broadcast(event, event.data.id)
  end
end
