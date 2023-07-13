defmodule ExshomeAutomation.Services.Workflow.Editor do
  @moduledoc """
  Editor logic for workflow.
  """

  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias ExshomeAutomation.Services.Workflow.{EditorItem, ItemProperties, Schema}
  alias ExshomeAutomation.Streams.EditorStream

  defstruct [
    :id,
    :items,
    :changes,
    :operation_pid,
    :operation_timestamp,
    dragged_items: %{},
    available_connectors: %{
      parent: %{},
      action: %{},
      connector: %{}
    }
  ]

  @type connector_data() :: %{
          position: ItemProperties.connector_position(),
          type: EditorItem.connection_type()
        }

  @type t() :: %__MODULE__{
          id: String.t(),
          items: %{
            String.t() => EditorItem.t()
          },
          changes: [Operation.t()],
          available_connectors: %{
            (type :: atom()) => %{EditorItem.remote_key() => connector_data()}
          },
          operation_pid: Operation.key(),
          operation_timestamp: DateTime.t() | nil,
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

  @spec put_operation_timestamp(t(), DateTime.t() | nil) :: t()
  def put_operation_timestamp(state, operation_timestamp) do
    %__MODULE__{state | operation_timestamp: operation_timestamp}
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
    items
    |> Map.values()
    |> Enum.sort(&(DateTime.compare(&1.updated_at, &2.updated_at) == :lt))
  end

  @spec get_item(t(), String.t()) :: EditorItem.t() | nil
  def get_item(%__MODULE__{items: items}, item_id) do
    Map.get(items, item_id, nil)
  end

  @spec select_item(t(), String.t()) :: t()
  def select_item(%__MODULE__{} = state, item_id) do
    selected_by = state.operation_pid

    state = clear_selected_by(state, selected_by)

    selected_items =
      state
      |> list_children_ids(item_id)
      |> MapSet.put(item_id)

    for id <- selected_items, reduce: state do
      state ->
        item =
          state
          |> get_item(id)
          |> EditorItem.set_selected_by(state.operation_pid)

        update_item(state, item)
    end
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
    %EditorItem{id: id} =
      item =
      type
      |> EditorItem.create(position)
      |> maybe_put_updated_at(state.operation_timestamp)

    change = %Operation.Insert{data: item, at: -1, key: state.operation_pid}

    %__MODULE__{state | items: Map.put(state.items, id, item)}
    |> put_change(change)
    |> update_connectors(item)
  end

  @spec maybe_put_updated_at(EditorItem.t(), DateTime.t() | nil) :: EditorItem.t()
  def maybe_put_updated_at(item, nil), do: item
  def maybe_put_updated_at(item, timestamp), do: EditorItem.put_updated_at(item, timestamp)

  @spec move_item(t(), String.t(), EditorItem.position(), EditorItem.connection_type()) :: t()
  def move_item(%__MODULE__{} = state, item_id, new_position, type \\ :hover) do
    %EditorItem{} = item = get_item(state, item_id)

    drag = type == :hover

    new_position = %{x: max(new_position.x, 0), y: max(new_position.y, 0)}
    initial_position = item.position
    diff = %{x: initial_position.x - new_position.x, y: initial_position.y - new_position.y}

    state
    |> update_position(item_id, diff, drag)
    |> update_dragged_by(item_id)
    |> update_parent_connections(item_id, type)
    |> move_children(item_id, diff, drag)
  end

  @spec update_position(t(), String.t(), EditorItem.position(), boolean()) :: t()
  defp update_position(%__MODULE__{} = state, item_id, %{x: diff_x, y: diff_y}, drag) do
    %EditorItem{position: position} =
      item =
      state
      |> get_item(item_id)
      |> EditorItem.set_drag(drag)

    new_position = %{x: position.x - diff_x, y: position.y - diff_y}

    item =
      item
      |> EditorItem.update_position(new_position)
      |> EditorItem.put_updated_at(state.operation_timestamp)

    state
    |> update_item(item)
    |> update_connectors(item)
  end

  @spec move_children(t(), String.t(), EditorItem.position(), boolean()) :: t()
  defp move_children(%__MODULE__{} = state, item_id, diff, drag) do
    for child_id <- list_children_ids(state, item_id), reduce: state do
      state -> update_position(state, child_id, diff, drag)
    end
  end

  @spec list_children_ids(t(), String.t()) :: MapSet.t(String.t())
  defp list_children_ids(%__MODULE__{} = state, item_id) do
    state
    |> recursive_list_children_ids([item_id], MapSet.new())
    |> MapSet.delete(item_id)
  end

  @spec recursive_list_children_ids(
          t(),
          ids_to_check :: [String.t()],
          result :: MapSet.t(String.t())
        ) :: MapSet.t(String.t())
  defp recursive_list_children_ids(_, [], result), do: result

  defp recursive_list_children_ids(%__MODULE__{} = state, [item_id | rest], result) do
    children_ids =
      state
      |> get_item(item_id)
      |> EditorItem.list_children_ids()
      |> Enum.reject(&MapSet.member?(result, &1))

    new_result =
      children_ids
      |> MapSet.new()
      |> MapSet.union(result)

    recursive_list_children_ids(state, rest ++ children_ids, new_result)
  end

  @spec update_siblings(t(), String.t(), connection_type :: :connected | :disconnected) :: t()
  defp update_siblings(%__MODULE__{} = state, item_id, connection_type) do
    case traverse_parents(state, item_id) do
      [] ->
        state

      [{root_id, _} | _] ->
        %{height: diff_height} = compute_item_size(state, item_id)
        %EditorItem{} = item = get_item(state, item_id)

        diff = %{
          x: 0,
          y: if(connection_type == :connected, do: -diff_height, else: diff_height)
        }

        item_ids_to_exclude =
          state
          |> list_children_ids(item_id)
          |> MapSet.put(item_id)

        affected_item_ids =
          state
          |> list_children_ids(root_id)
          |> MapSet.difference(item_ids_to_exclude)

        for affected_id <- affected_item_ids, reduce: state do
          state ->
            %EditorItem{} = affected_item = get_item(state, affected_id)

            if item.position.y < affected_item.position.y do
              update_position(state, affected_id, diff, false)
            else
              state
            end
        end
    end
  end

  @spec compute_item_size(t(), String.t()) :: ItemProperties.size()
  defp compute_item_size(%__MODULE__{} = state, item_id, previous_size \\ %{height: 0, width: 0}) do
    %EditorItem{} = item = get_item(state, item_id)

    item_size = %{
      height: item.raw_size.height + previous_size.height,
      width: max(item.raw_size.width, previous_size.width)
    }

    case item.connected_items[{:action, :next_action}] do
      nil ->
        item_size

      %{remote_key: {child_id, _}} ->
        compute_item_size(state, child_id, item_size)
    end
  end

  @spec refresh_connection_sizes(t(), [ItemProperties.remote_key()]) :: t()
  defp refresh_connection_sizes(%__MODULE__{} = state, connections) do
    for {parent_id, parent_key} <- Enum.reverse(connections), reduce: state do
      state ->
        %EditorItem{} = parent = get_item(state, parent_id)

        case parent.connected_items[parent_key] do
          %{remote_key: {child_id, _}, type: :connected} = connection ->
            child_size = compute_item_size(state, child_id)

            updated_connection = %{
              connection
              | width: child_size.width,
                height: child_size.height
            }

            parent = EditorItem.put_connection(parent, parent_key, updated_connection)

            update_item(state, parent)

          _ ->
            state
        end
    end
  end

  @spec traverse_parents(t(), String.t(), [ItemProperties.remote_key()]) :: [
          ItemProperties.remote_key()
        ]
  defp traverse_parents(%__MODULE__{} = state, item_id, result \\ []) do
    %EditorItem{} = item = get_item(state, item_id)
    parent_key = EditorItem.get_parent_key(item)

    case item.connected_items[parent_key] do
      %{remote_key: {parent_id, _} = parent_key} ->
        traverse_parents(state, parent_id, [parent_key | result])

      _ ->
        result
    end
  end

  @spec stop_dragging(t(), String.t(), EditorItem.position()) :: t()
  def stop_dragging(%__MODULE__{} = state, item_id, new_position) do
    state =
      state
      |> move_item(item_id, new_position, :connected)
      |> maybe_adjust_item_position(item_id)

    %EditorItem{} =
      item =
      state
      |> get_item(item_id)
      |> EditorItem.set_drag(false)

    state
    |> update_item(item)
    |> remove_dragged_item_id()
  end

  @spec maybe_adjust_item_position(t(), String.t()) :: t()
  defp maybe_adjust_item_position(%__MODULE__{} = state, item_id) do
    item = get_item(state, item_id)
    parent_key = EditorItem.get_parent_key(item)

    case item.connected_items[parent_key] do
      %{type: :connected, remote_key: remote_key} ->
        own_connector_position = fetch_connector_data(state, {item_id, parent_key}).position
        other_connector_position = fetch_connector_data(state, remote_key).position
        new_x = item.position.x - own_connector_position.x + other_connector_position.x
        new_y = item.position.y - own_connector_position.y + other_connector_position.y
        move_item(state, item_id, %{x: new_x, y: new_y}, :connected)

      _ ->
        state
    end
  end

  @spec update_dragged_by(t(), String.t()) :: t()
  defp update_dragged_by(%__MODULE__{operation_pid: nil} = state, _), do: state

  defp update_dragged_by(%__MODULE__{} = state, item_id) do
    update_in(state.dragged_items, &Map.put(&1, state.operation_pid, item_id))
  end

  @spec remove_dragged_item_id(t()) :: t()
  defp remove_dragged_item_id(%__MODULE__{operation_pid: nil} = state), do: state

  defp remove_dragged_item_id(%__MODULE__{} = state) do
    update_in(state.dragged_items, &Map.put(&1, state.operation_pid, nil))
  end

  def delete_item(%__MODULE__{} = state, item_id) do
    ids_to_delete =
      state
      |> list_children_ids(item_id)
      |> MapSet.put(item_id)

    for id <- ids_to_delete, reduce: state do
      state ->
        %EditorItem{} = item = get_item(state, id)
        change = %Operation.Delete{data: item, key: state.operation_pid}

        %__MODULE__{state | items: Map.delete(state.items, item.id)}
        |> delete_connectors(item)
        |> put_change(change)
    end
  end

  @spec update_item(t(), EditorItem.t()) :: t()
  defp update_item(%__MODULE__{} = state, item) do
    change = %Operation.Update{data: item, at: -1, key: state.operation_pid}

    %__MODULE__{state | items: Map.put(state.items, item.id, item)}
    |> put_change(change)
  end

  @spec update_connectors(t(), EditorItem.t()) :: t()
  defp update_connectors(%__MODULE__{} = state, %EditorItem{} = item) do
    for {connector_key, data} <- item.connectors, reduce: state do
      state ->
        connection = item.connected_items[connector_key]

        connector_data = %{
          position: %{data | x: item.position.x + data.x, y: item.position.y + data.y},
          type: if(connection, do: connection.type, else: nil)
        }

        key = EditorItem.remote_key(item, connector_key)
        connector_type = ItemProperties.connector_type(connector_key)

        update_in(
          state.available_connectors[connector_type],
          &Map.put(&1, key, connector_data)
        )
    end
  end

  @spec delete_connectors(t(), EditorItem.t()) :: t()
  defp delete_connectors(%__MODULE__{} = state, %EditorItem{} = item) do
    for {connector_key, _} <- item.connectors, reduce: state do
      state ->
        key = EditorItem.remote_key(item, connector_key)
        connector_type = ItemProperties.connector_type(connector_key)

        update_in(
          state.available_connectors[connector_type],
          &Map.delete(&1, key)
        )
    end
  end

  @spec update_parent_connections(t(), String.t(), EditorItem.connection_type()) :: t()
  defp update_parent_connections(%__MODULE__{} = state, item_id, connection_type) do
    %EditorItem{} = item = get_item(state, item_id)
    parent_key = EditorItem.get_parent_key(item)

    state =
      case item.connected_items[parent_key] do
        %{remote_key: remote_key} ->
          parent_connections =
            state
            |> traverse_parents(item_id)
            |> Enum.reverse()

          state
          |> update_siblings(item_id, :disconnected)
          |> disconnect_items(remote_key, {item_id, parent_key})
          |> refresh_connection_sizes(parent_connections)

        _ ->
          state
      end

    if parent_key do
      remote_key = EditorItem.remote_key(item, parent_key)
      connection = intersecting_connector(state, remote_key)

      if connection do
        state =
          state
          |> connect_items(remote_key, connection, connection_type)
          |> update_siblings(item_id, :connected)

        parent_connections =
          state
          |> traverse_parents(item_id)
          |> Enum.reverse()

        refresh_connection_sizes(state, parent_connections)
      else
        state
      end
    else
      state
    end
  end

  @spec intersecting_connector(t(), EditorItem.remote_key()) :: EditorItem.remote_key() | nil
  defp intersecting_connector(%__MODULE__{} = state, {_, parent_key} = remote_key) do
    own_data = fetch_connector_data(state, remote_key)
    connector_type = ItemProperties.parent_type(parent_key)

    state.available_connectors
    |> Map.fetch!(connector_type)
    |> Enum.filter(fn {_, candidate_data} ->
      not_connected? = candidate_data.type != :connected

      intersects? =
        ItemProperties.position_intersects?(
          own_data.position,
          candidate_data.position
        )

      not_connected? && intersects?
    end)
    |> Enum.map(fn {key, _data} -> key end)
    |> Enum.sort_by(
      fn {id, _} -> get_item(state, id).updated_at end,
      fn date_1, date_2 -> DateTime.compare(date_1, date_2) == :gt end
    )
    |> List.first()
  end

  @spec fetch_connector_data(t(), EditorItem.remote_key()) :: connector_data()
  defp fetch_connector_data(%__MODULE__{} = state, {_, connector_key} = key) do
    connector_type = ItemProperties.connector_type(connector_key)

    state.available_connectors
    |> Map.fetch!(connector_type)
    |> Map.fetch!(key)
  end

  @spec connect_items(
          t(),
          parent :: EditorItem.remote_key(),
          child :: EditorItem.remote_key(),
          EditorItem.connection_type()
        ) :: t()
  defp connect_items(
         %__MODULE__{} = state,
         {parent_id, parent_key} = parent,
         {child_id, child_key} = child,
         connection_type
       ) do
    connections = [
      {child_id, child_key, parent},
      {parent_id, parent_key, child}
    ]

    for {id, own_key, {remote_id, _} = remote_key} <- connections, reduce: state do
      state ->
        %{height: remote_height, width: remote_width} = compute_item_size(state, remote_id)

        item =
          state
          |> get_item(id)
          |> EditorItem.put_connection(own_key, %{
            remote_key: remote_key,
            type: connection_type,
            height: remote_height,
            width: remote_width
          })

        state
        |> update_connectors(item)
        |> update_item(item)
    end
  end

  @spec disconnect_items(
          t(),
          parent :: EditorItem.remote_key(),
          child :: EditorItem.remote_key()
        ) :: t()
  defp disconnect_items(%__MODULE__{} = state, parent, child) do
    for {id, key} <- [parent, child], reduce: state do
      state ->
        item =
          state
          |> get_item(id)
          |> EditorItem.delete_connection(key)

        state
        |> update_connectors(item)
        |> update_item(item)
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
