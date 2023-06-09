defmodule ExshomeAutomation.Services.Workflow.Editor do
  @moduledoc """
  Editor logic for workflow.
  """

  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias ExshomeAutomation.Services.Workflow.{EditorItem, Schema}
  alias ExshomeAutomation.Streams.EditorStream

  defstruct [
    :id,
    :items,
    :changes,
    :operation_pid,
    dragged_by: %{},
    subscribers: MapSet.new()
  ]

  @type t() :: %__MODULE__{
          id: String.t(),
          items: %{
            String.t() => EditorItem.t()
          },
          changes: [Operation.t()],
          operation_pid: Operation.key(),
          dragged_by: %{pid() => String.t()},
          subscribers: MapSet.t(pid())
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
  end

  @spec subscribe(t(), Operation.key()) :: t()
  def subscribe(%__MODULE__{} = state, operation_pid) do
    if operation_pid && !MapSet.member?(state.subscribers, operation_pid) do
      Process.link(operation_pid)
      update_in(state.subscribers, &MapSet.put(&1, operation_pid))
    else
      state
    end
  end

  @spec unsubscribe(t(), Operation.key()) :: t()
  def unsubscribe(%__MODULE__{} = state, operation_pid) do
    if MapSet.member?(state.subscribers, operation_pid) do
      Process.unlink(operation_pid)

      update_in(state.subscribers, &MapSet.delete(&1, operation_pid))
      |> clear_selected_by(operation_pid)
    else
      state
    end
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
        item = %EditorItem{item | selected_by: nil, drag: false}

        state
        |> remove_dragged_by(item)
        |> update_item(item)
    end
  end

  @spec create_item(t(), config :: map()) :: t()
  def create_item(%__MODULE__{} = state, config) do
    %EditorItem{id: id} = item = EditorItem.create(config)
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
    |> remove_dragged_by(item)
  end

  @spec update_dragged_by(t(), EditorItem.t()) :: t()
  defp update_dragged_by(%__MODULE__{operation_pid: nil} = state, _), do: state

  defp update_dragged_by(%__MODULE__{} = state, %EditorItem{id: id}) do
    update_in(state.dragged_by, &Map.put(&1, state.operation_pid, id))
  end

  @spec remove_dragged_by(t(), EditorItem.t()) :: t()
  defp remove_dragged_by(%__MODULE__{} = state, %EditorItem{} = item) do
    dragged_by =
      state.dragged_by
      |> Enum.reject(fn {_, item_id} -> item.id == item_id end)
      |> Enum.into(%{})

    %__MODULE__{state | dragged_by: dragged_by}
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
