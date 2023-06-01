defmodule ExshomeAutomation.Services.Workflow.Editor do
  @moduledoc """
  Editor logic for workflow.
  """

  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias ExshomeAutomation.Services.Workflow.Schema
  alias ExshomeAutomation.Streams.EditorStream

  defmodule Item do
    @moduledoc """
    Editor item.
    """
    defstruct [
      :id,
      :type,
      position: %{x: 0, y: 0}
    ]

    @type position() :: %{
            x: number(),
            y: number()
          }

    @type t() :: %__MODULE__{
            id: String.t(),
            position: position(),
            type: String.t()
          }

    @spec create(map()) :: t()
    def create(%{type: type, position: position}) when is_binary(type) do
      %__MODULE__{
        id: Ecto.UUID.autogenerate(),
        position: normalize_position(position),
        type: type
      }
    end

    @spec update_position(t(), position()) :: t()
    def update_position(%__MODULE__{} = item, position) do
      %__MODULE__{
        item
        | position: normalize_position(position)
      }
    end

    defp normalize_position(%{x: x, y: y}) do
      %{x: max(x, 0), y: max(y, 0)}
    end
  end

  defstruct [
    :id,
    :items,
    :changes,
    :operation_key
  ]

  @type t() :: %__MODULE__{
          id: String.t(),
          items: %{
            String.t() => Item.t()
          },
          changes: [Operation.t()],
          operation_key: Operation.key()
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
    items =
      for _ <- 1..5, into: %{} do
        item = Item.create(%{type: "rectangle", position: %{x: 0, y: 0}})
        {item.id, item}
      end

    state = %__MODULE__{state | items: items}

    put_change(
      state,
      %Operation.ReplaceAll{data: list_items(state), key: state.operation_key}
    )
  end

  @spec put_operation_key(t(), Operation.key()) :: t()
  def put_operation_key(state, operation_key) do
    %__MODULE__{state | operation_key: operation_key}
  end

  @spec list_items(t()) :: [Item.t()]
  def list_items(%__MODULE__{items: items}) do
    Map.values(items)
  end

  @spec get_item(t(), String.t()) :: Item.t() | nil
  def get_item(%__MODULE__{items: items}, item_id) do
    Map.get(items, item_id, nil)
  end

  @spec create_item(t(), config :: map()) :: t()
  def create_item(%__MODULE__{} = state, config) do
    %Item{id: id} = item = Item.create(config)
    change = %Operation.Insert{data: item, at: -1, key: state.operation_key}

    %__MODULE__{state | items: Map.put(state.items, id, item)}
    |> put_change(change)
  end

  @spec move_item(t(), String.t(), Item.position()) :: t()
  def move_item(%__MODULE__{} = state, item_id, new_position) do
    %Item{} =
      item =
      state
      |> get_item(item_id)
      |> Item.update_position(new_position)

    change = %Operation.Update{data: item, at: -1, key: state.operation_key}

    %__MODULE__{state | items: Map.put(state.items, item.id, item)}
    |> put_change(change)
  end

  def delete_item(%__MODULE__{} = state, id) do
    %Item{} = item = get_item(state, id)
    change = %Operation.Delete{data: item, key: state.operation_key}

    %__MODULE__{state | items: Map.delete(state.items, item.id)}
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
    %Operation.Batch{operations: Enum.reverse(changes)}
  end
end
