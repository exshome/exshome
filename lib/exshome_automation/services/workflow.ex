defmodule ExshomeAutomation.Services.Workflow do
  @moduledoc """
  A module for automation workflows.
  """

  alias Exshome.DataStream.Operation
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias Exshome.Service
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

  @type editor_item_response() :: :ok | {:error, reason :: String.t()}

  use Exshome.Service.DependencyService,
    app: ExshomeAutomation,
    name: "automation_workflow",
    parent_module: WorkflowSupervisor

  @impl ServiceBehaviour
  def init(%ServiceState{} = state) do
    {__MODULE__, id} = state.id

    schema = Schema.get!(id)
    value = schema_to_workflow_data(schema)

    register_workflow_data(value)

    state
    |> update_value(fn _ -> value end)
    |> update_data(fn _ -> Editor.blank_editor(schema.id) end)
    |> update_editor(nil, &Editor.load_editor(&1, schema))
  end

  @impl ServiceBehaviour
  def handle_stop(_reason, %ServiceState{value: value} = state) do
    :ok = remove_workflow_data(value)
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

  @spec create_item(
          workflow_id :: String.t(),
          type :: String.t(),
          position :: EditorItem.position()
        ) :: :ok
  def create_item(workflow_id, type, position) do
    call(workflow_id, {:create_item, type, position})
  end

  @spec get_item!(workflow_id :: String.t(), item_id :: String.t()) :: EditorItem.t()
  def get_item!(workflow_id, item_id) do
    %EditorItem{} = call(workflow_id, {:get_item, item_id})
  end

  @spec select_item(workflow_id :: String.t(), item_id :: String.t()) :: editor_item_response()
  def select_item(workflow_id, item_id) do
    call(workflow_id, {:select_item, item_id})
  end

  @spec move_item(
          workflow_id :: String.t(),
          item_id :: String.t(),
          position :: EditorItem.position()
        ) :: editor_item_response()
  def move_item(workflow_id, item_id, position) do
    call(workflow_id, {{:move_item, item_id}, position})
  end

  @spec stop_dragging(
          workflow_id :: String.t(),
          item_id :: String.t(),
          position :: EditorItem.position()
        ) :: editor_item_response()
  def stop_dragging(workflow_id, item_id, position) do
    call(workflow_id, {{:stop_dragging, item_id}, position})
  end

  @spec delete_item(workflow_id :: String.t(), item_id :: String.t()) :: editor_item_response()
  def delete_item(workflow_id, item_id) do
    call(workflow_id, {:delete_item, item_id})
  end

  @spec rename(String.t(), String.t()) :: :ok
  def rename(id, name), do: call(id, {:rename, name})

  @impl ServiceBehaviour
  def handle_call(:list_items, _, %ServiceState{} = state) do
    {:reply, Editor.list_items(state.data), state}
  end

  def handle_call({:get_item, item_id}, _, %ServiceState{} = state) do
    {:reply, Editor.get_item(state.data, item_id), state}
  end

  def handle_call({:create_item, type, position}, {request_pid, _}, %ServiceState{} = state) do
    state = update_editor(state, request_pid, &Editor.create_item(&1, type, position))
    {:reply, :ok, state}
  end

  def handle_call({:select_item, item_id}, {request_pid, _}, %ServiceState{} = state) do
    item_operation(
      state,
      request_pid,
      item_id,
      &Editor.select_item(&1, item_id)
    )
  end

  def handle_call({{:move_item, item_id}, position}, {request_pid, _}, %ServiceState{} = state) do
    item_operation(
      state,
      request_pid,
      item_id,
      &Editor.move_item(&1, item_id, position)
    )
  end

  def handle_call(
        {{:stop_dragging, item_id}, position},
        {request_pid, _},
        %ServiceState{} = state
      ) do
    item_operation(
      state,
      request_pid,
      item_id,
      &Editor.stop_dragging(&1, item_id, position)
    )
  end

  def handle_call({:delete_item, item_id}, {request_pid, _}, %ServiceState{} = state) do
    item_operation(
      state,
      request_pid,
      item_id,
      &Editor.delete_item(&1, item_id)
    )
  end

  def handle_call({:rename, name}, _, %ServiceState{} = state) do
    value =
      state.value.id
      |> Schema.get!()
      |> Schema.rename!(name)
      |> schema_to_workflow_data()

    :ok = broadcast_changes(%Operation.Update{data: value})
    state = update_value(state, fn _ -> value end)
    {:reply, :ok, state}
  end

  @impl ServiceBehaviour
  def handle_info({:EXIT, pid, _reason}, %ServiceState{} = state) do
    state = update_editor(state, pid, &Editor.clear_process_data(&1, pid))
    {:noreply, state}
  end

  defp call(id, message) when is_binary(id) do
    Service.call({__MODULE__, id}, message)
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
    :ok = Emitter.broadcast(WorkflowStateStream, changes)
    :ok = Emitter.broadcast({WorkflowStateStream, changes.data.id}, changes)
  end

  @spec item_operation(
          ServiceState.t(),
          Operation.key(),
          item_id :: String.t(),
          (Editor.t() -> Editor.t())
        ) :: {:reply, editor_item_response(), ServiceState.t()}
  def item_operation(state, pid, item_id, update_fn) do
    case Editor.get_item(state.data, item_id) do
      %EditorItem{} ->
        state = update_editor(state, pid, update_fn)
        {:reply, :ok, state}

      _ ->
        {:reply, {:error, "Item not found"}, state}
    end
  end

  @spec update_editor(ServiceState.t(), Operation.key(), (Editor.t() -> Editor.t())) ::
          ServiceState.t()
  defp update_editor(%ServiceState{} = state, pid, update_fn) do
    operation_timestamp = DateTime.now!("Etc/UTC")

    update_data(state, fn editor ->
      editor
      |> Editor.put_operation_timestamp(operation_timestamp)
      |> Editor.put_operation_pid(pid)
      |> update_fn.()
      |> Editor.broadcast_changes()
      |> Editor.put_operation_pid(nil)
      |> Editor.put_operation_timestamp(nil)
    end)
  end
end
