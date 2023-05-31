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
      :x,
      :y,
      :type
    ]

    @type t() :: %__MODULE__{
            id: String.t(),
            x: number(),
            y: number(),
            type: String.t()
          }

    @spec create_default_item(type :: String.t()) :: t()
    def create_default_item(type) when is_binary(type) do
      %__MODULE__{
        id: Ecto.UUID.autogenerate(),
        x: 0,
        y: 0,
        type: type
      }
    end
  end

  defstruct [
    :id,
    :items,
    :changes
  ]

  @type t() :: %__MODULE__{
          id: String.t(),
          items: %{
            String.t() => Item.t()
          },
          changes: [Operation.t()]
        }

  @spec load_editor(Schema.t()) :: t()
  def load_editor(%Schema{} = schema) do
    state = %__MODULE__{
      id: schema.id,
      items: %{},
      changes: []
    }

    change = %Operation.ReplaceAll{data: get_items(state)}

    state
    |> put_change(change)
    |> broadcast_changes()
  end

  @spec get_items(t()) :: [Item.t()]
  def get_items(%__MODULE__{items: items}) do
    Map.values(items)
  end

  @spec create_item(t(), type :: String.t()) :: t()
  def create_item(%__MODULE__{} = state, type) do
    %Item{id: id} = item = Item.create_default_item(type)
    change = %Operation.Insert{data: item, at: -1}

    %__MODULE__{state | items: Map.put(state.items, id, item)}
    |> put_change(change)
    |> broadcast_changes()
  end

  @spec put_change(t(), Operation.single_operation()) :: t()
  defp put_change(%__MODULE__{} = state, operation) do
    %__MODULE__{state | changes: [operation | state.changes]}
  end

  @spec broadcast_changes(t()) :: t()
  defp broadcast_changes(%__MODULE__{id: id} = state) do
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
