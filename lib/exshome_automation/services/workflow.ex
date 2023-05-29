defmodule ExshomeAutomation.Services.Workflow do
  @moduledoc """
  A module for automation workflows.
  """

  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency.NotReady
  alias Exshome.SystemRegistry
  alias ExshomeAutomation.Services.Workflow.Editor
  alias ExshomeAutomation.Services.Workflow.Schema
  alias ExshomeAutomation.Services.Workflow.WorkflowSupervisor
  alias ExshomeAutomation.Streams.WorkflowStateStream

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

    state
    |> update_value(fn _ -> value end)
    |> update_data(fn _ -> Editor.blank_editor() end)
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

  @spec get_editor_state(String.t()) :: [Editor.t()]
  def get_editor_state(id), do: call(id, :get_editor_state)

  @spec add_editor_item(String.t(), String.t()) :: :ok
  def add_editor_item(id, type), do: call(id, {:add_editor_item, type})

  @spec rename(String.t(), String.t()) :: :ok
  def rename(id, name), do: call(id, {:rename, name})

  @impl GenServerDependency
  def handle_call(:get_editor_state, _, %DependencyState{} = state) do
    {:reply, state.data, state}
  end

  @impl GenServerDependency
  def handle_call({:add_editor_item, type}, _, %DependencyState{} = state) do
    item = Editor.create_default_item(type)
    state = update_data(state, &Editor.add_item(&1, item))
    {:reply, :ok, state}
  end

  @impl GenServerDependency
  def handle_call({:rename, name}, _, %DependencyState{} = state) do
    value =
      state.value.id
      |> Schema.get!()
      |> Schema.rename!(name)
      |> schema_to_workflow_data()

    :ok = broadcast_changes(%Operation.Update{data: value})
    state = update_value(state, fn _ -> value end)
    {:reply, :ok, state}
  end

  defp call(id, message) when is_binary(id) do
    GenServerDependency.call({__MODULE__, id}, message)
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
    :ok = broadcast_changes(%Operation.Insert{data: workflow_data})
  end

  @spec remove_workflow_data(t() | atom()) :: :ok
  def remove_workflow_data(NotReady), do: :ok

  def remove_workflow_data(%__MODULE__{} = workflow_data) do
    :ok = SystemRegistry.remove!(__MODULE__, workflow_data.id)
    :ok = broadcast_changes(%Operation.Delete{data: workflow_data})
  end

  defp broadcast_changes(%{data: %__MODULE__{}} = changes) do
    :ok = DataStream.broadcast(WorkflowStateStream, changes)
    :ok = DataStream.broadcast({WorkflowStateStream, changes.data.id}, changes)
  end
end
