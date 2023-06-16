defmodule ExshomeAutomation.Services.Workflow.Editor do
  @moduledoc """
  Editor logic for workflow.
  """

  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias ExshomeAutomation.Services.Workflow.{EditorItem, ItemConfig, Schema}
  alias ExshomeAutomation.Streams.EditorStream

  defstruct [
    :id,
    :items,
    :changes,
    :operation_pid,
    dragged_items: %{},
    available_connectors: %{
      action_in: %{},
      action_out: %{},
      connector_in: %{},
      connector_out: %{}
    }
  ]

  @type t() :: %__MODULE__{
          id: String.t(),
          items: %{
            String.t() => EditorItem.t()
          },
          changes: [Operation.t()],
          available_connectors: %{
            (type :: atom()) => %{
              {item_id :: String.t(), ItemConfig.Properties.connector_key()} =>
                ItemConfig.Properties.connector_position()
            }
          },
          operation_pid: Operation.key(),
          dragged_items: %{pid() => String.t() | nil}
        }

  @spec blank_editor(id :: String.t()) :: t()
  def blank_editor(id) do
    %__MODULE__{
      id: id,
      items: %{},
      changes: []
    }
  end

  @spec load_editor(t(), Schema.t()) :: t()
  def load_editor(%__MODULE__{} = state, %Schema{} = _schema) do
    state = %__MODULE__{state | items: %{}}

    put_change(
      state,
      %Operation.ReplaceAll{data: list_items(state), key: state.operation_pid}
    )
  end

  @spec put_operation_pid(t(), Operation.key()) :: t()
  def put_operation_pid(state, operation_pid) do
    %__MODULE__{state | operation_pid: operation_pid}
    |> regiter_client(operation_pid)
  end

  @spec regiter_client(t(), Operation.key()) :: t()
  defp regiter_client(%__MODULE__{} = state, operation_pid) do
    if operation_pid && !Map.has_key?(state.dragged_items, operation_pid) do
      Process.link(operation_pid)
      update_in(state.dragged_items, &Map.put(&1, operation_pid, nil))
    else
      state
    end
  end

  @spec clear_process_data(t(), Operation.key()) :: t()
  def clear_process_data(%__MODULE__{} = state, operation_pid) do
    Process.unlink(operation_pid)

    dragged_item_id = state.dragged_items[operation_pid]

    state =
      case get_item(state, dragged_item_id) do
        %EditorItem{position: position} -> stop_dragging(state, dragged_item_id, position)
        _ -> state
      end

    update_in(state.dragged_items, &Map.delete(&1, operation_pid))
    |> clear_selected_by(operation_pid)
  end

  @spec list_items(t()) :: [EditorItem.t()]
  def list_items(%__MODULE__{items: items}) do
    Map.values(items)
  end

  @spec get_item(t(), String.t()) :: EditorItem.t() | nil
  def get_item(%__MODULE__{items: items}, item_id) do
    Map.get(items, item_id, nil)
  end

  @spec select_item(t(), String.t()) :: t()
  def select_item(%__MODULE__{} = state, item_id) do
    selected_by = state.operation_pid

    state = clear_selected_by(state, selected_by)

    item =
      state
      |> get_item(item_id)
      |> EditorItem.set_selected_by(state.operation_pid)

    update_item(state, item)
  end

  @spec clear_selected_by(t(), Operation.key()) :: t()
  defp clear_selected_by(state, nil), do: state

  defp clear_selected_by(state, pid) do
    for %EditorItem{} = item <- list_items(state), item.selected_by == pid, reduce: state do
      state ->
        item = %EditorItem{item | selected_by: nil}

        update_item(state, item)
    end
  end

  @spec create_item(t(), type :: String.t(), position :: EditorItem.position()) :: t()
  def create_item(%__MODULE__{} = state, type, position) do
    %EditorItem{id: id} = item = EditorItem.create(type, position)
    change = %Operation.Insert{data: item, at: -1, key: state.operation_pid}

    %__MODULE__{state | items: Map.put(state.items, id, item)}
    |> put_change(change)
  end

  @spec move_item(t(), String.t(), EditorItem.position()) :: t()
  def move_item(%__MODULE__{} = state, item_id, new_position) do
    %EditorItem{} =
      item =
      state
      |> get_item(item_id)
      |> EditorItem.set_drag(true)
      |> EditorItem.update_position(new_position)

    state
    |> update_item(item)
    |> update_dragged_by(item)
    |> update_item_connectors(item)
  end

  @spec stop_dragging(t(), String.t(), EditorItem.position()) :: t()
  def stop_dragging(%__MODULE__{} = state, item_id, new_position) do
    state = move_item(state, item_id, new_position)

    %EditorItem{} =
      item =
      state
      |> get_item(item_id)
      |> EditorItem.set_drag(false)

    state
    |> update_item(item)
    |> remove_dragged_item_id()
  end

  @spec update_dragged_by(t(), EditorItem.t()) :: t()
  defp update_dragged_by(%__MODULE__{operation_pid: nil} = state, _), do: state

  defp update_dragged_by(%__MODULE__{} = state, %EditorItem{id: id}) do
    update_in(state.dragged_items, &Map.put(&1, state.operation_pid, id))
  end

  @spec remove_dragged_item_id(t()) :: t()
  defp remove_dragged_item_id(%__MODULE__{operation_pid: nil} = state), do: state

  defp remove_dragged_item_id(%__MODULE__{} = state) do
    update_in(state.dragged_items, &Map.put(&1, state.operation_pid, nil))
  end

  def delete_item(%__MODULE__{} = state, id) do
    %EditorItem{} = item = get_item(state, id)
    change = %Operation.Delete{data: item, key: state.operation_pid}

    %__MODULE__{state | items: Map.delete(state.items, item.id)}
    |> put_change(change)
  end

  @spec update_item(t(), EditorItem.t()) :: t()
  defp update_item(%__MODULE__{} = state, item) do
    change = %Operation.Update{data: item, at: -1, key: state.operation_pid}

    %__MODULE__{state | items: Map.put(state.items, item.id, item)}
    |> put_change(change)
  end

  @spec update_item_connectors(t(), EditorItem.t()) :: t()
  defp update_item_connectors(%__MODULE__{} = state, %EditorItem{} = item) do
    for {{connector_type, _} = connector_key, data} <- item.connectors, reduce: state do
      state ->
        connector_data = %{data | x: item.position.x + data.x, y: item.position.y + data.y}
        key = {item.id, connector_key}

        update_in(
          state.available_connectors[connector_type],
          &Map.put(&1, key, connector_data)
        )
    end
  end

  @spec put_change(t(), Operation.single_operation()) :: t()
  defp put_change(%__MODULE__{} = state, operation) do
    %__MODULE__{state | changes: [operation | state.changes]}
  end

  @spec broadcast_changes(t()) :: t()
  def broadcast_changes(%__MODULE__{id: id} = state) do
    changes = fetch_changes(state)
    :ok = DataStream.broadcast({EditorStream, id}, changes)

    %__MODULE__{state | changes: []}
  end

  @spec fetch_changes(t()) :: Operation.t()
  defp fetch_changes(%__MODULE__{changes: [operation]}), do: operation

  defp fetch_changes(%__MODULE__{changes: changes}) do
    operations = deduplicate_updates(MapSet.new(), changes, [])
    %Operation.Batch{operations: operations}
  end

  @spec deduplicate_updates(
          updated_ids :: MapSet.t(),
          non_processed_changes :: [Operation.t()],
          result :: [Operation.t()]
        ) :: [Operation.t()]
  defp deduplicate_updates(_, [], operations), do: operations

  defp deduplicate_updates(
         %MapSet{} = updated_ids,
         [%Operation.Update{data: %EditorItem{}} = operation | other],
         result
       ) do
    item_id = operation.data.id

    if MapSet.member?(updated_ids, item_id) do
      deduplicate_updates(updated_ids, other, result)
    else
      deduplicate_updates(
        MapSet.put(updated_ids, item_id),
        other,
        [operation | result]
      )
    end
  end

  defp deduplicate_updates(updated_ids, [operation | other], result) do
    deduplicate_updates(updated_ids, other, [operation | result])
  end
end
