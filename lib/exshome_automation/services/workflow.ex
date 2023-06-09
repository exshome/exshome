defmodule ExshomeAutomation.Services.Workflow do
  @moduledoc """
  A module for automation workflows.
  """

  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency.NotReady
  alias Exshome.SystemRegistry
  alias ExshomeAutomation.Services.Workflow.Editor
  alias ExshomeAutomation.Services.Workflow.EditorItem
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

    schema = Schema.get!(id)
    value = schema_to_workflow_data(schema)

    register_workflow_data(value)

    state
    |> update_value(fn _ -> value end)
    |> update_data(fn _ -> Editor.blank_editor(schema.id) end)
    |> update_editor(nil, &Editor.load_editor(&1, schema))
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

  @spec list_items(String.t()) :: [EditorItem.t()] | NotReady
  def list_items(id), do: call(id, :list_items)

  @spec create_item(workflow_id :: String.t(), config :: map()) :: :ok
  def create_item(workflow_id, config) do
    call(workflow_id, {:create_item, config})
  end

  @spec get_item!(workflow_id :: String.t(), item_id :: String.t()) :: EditorItem.t()
  def get_item!(workflow_id, item_id) do
    %EditorItem{} = call(workflow_id, {:get_item, item_id})
  end

  @spec select_item!(workflow_id :: String.t(), item_id :: String.t()) :: :ok
  def select_item!(workflow_id, item_id) do
    item = get_item!(workflow_id, item_id)
    call(workflow_id, {:select_item, item.id})
  end

  @spec move_item!(
          workflow_id :: String.t(),
          item_id :: String.t(),
          position :: EditorItem.position()
        ) :: :ok
  def move_item!(workflow_id, item_id, position) do
    item = get_item!(workflow_id, item_id)
    call(workflow_id, {{:move_item, item.id}, position})
  end

  @spec stop_dragging!(
          workflow_id :: String.t(),
          item_id :: String.t(),
          position :: EditorItem.position()
        ) :: :ok
  def stop_dragging!(workflow_id, item_id, position) do
    item = get_item!(workflow_id, item_id)
    call(workflow_id, {{:stop_dragging, item.id}, position})
  end

  @spec delete_item!(workflow_id :: String.t(), item_id :: String.t()) :: :ok
  def delete_item!(workflow_id, item_id) do
    item = get_item!(workflow_id, item_id)
    call(workflow_id, {:delete_item, item.id})
  end

  @spec rename(String.t(), String.t()) :: :ok
  def rename(id, name), do: call(id, {:rename, name})

  @impl GenServerDependency
  def handle_call(:list_items, _, %DependencyState{} = state) do
    {:reply, Editor.list_items(state.data), state}
  end

  def handle_call({:get_item, item_id}, _, %DependencyState{} = state) do
    {:reply, Editor.get_item(state.data, item_id), state}
  end

  def handle_call({:create_item, config}, {request_pid, _}, %DependencyState{} = state) do
    state = update_editor(state, request_pid, &Editor.create_item(&1, config))
    {:reply, :ok, state}
  end

  def handle_call({:select_item, item_id}, {request_pid, _}, %DependencyState{} = state) do
    state = update_editor(state, request_pid, &Editor.select_item(&1, item_id))
    {:reply, :ok, state}
  end

  def handle_call({{:move_item, item_id}, position}, {request_pid, _}, %DependencyState{} = state) do
    state = update_editor(state, request_pid, &Editor.move_item(&1, item_id, position))
    {:reply, :ok, state}
  end

  def handle_call(
        {{:stop_dragging, item_id}, position},
        {request_pid, _},
        %DependencyState{} = state
      ) do
    state = update_editor(state, request_pid, &Editor.stop_dragging(&1, item_id, position))
    {:reply, :ok, state}
  end

  def handle_call({:delete_item, item_id}, {request_pid, _}, %DependencyState{} = state) do
    state = update_editor(state, request_pid, &Editor.delete_item(&1, item_id))
    {:reply, :ok, state}
  end

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

  @impl GenServerDependency
  def handle_info({:EXIT, pid, _reason}, %DependencyState{} = state) do
    state = update_editor(state, pid, &Editor.unsubscribe(&1, pid))
    {:noreply, state}
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

  @spec update_editor(DependencyState.t(), Operation.key(), (Editor.t() -> Editor.t())) ::
          DependencyState.t()
  defp update_editor(%DependencyState{} = state, pid, update_fn) do
    update_data(state, fn editor ->
      editor
      |> Editor.subscribe(pid)
      |> Editor.put_operation_pid(pid)
      |> update_fn.()
      |> Editor.broadcast_changes()
      |> Editor.put_operation_pid(nil)
    end)
  end
end
