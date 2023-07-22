defmodule ExshomeAutomation.Services.Workflow.EditorItem do
  @moduledoc """
  Editor item.
  """

  alias ExshomeAutomation.Services.Workflow.ItemConfig
  alias ExshomeAutomation.Services.Workflow.ItemProperties

  @parent_keys [:parent_action, :parent_connector]

  defstruct [
    :id,
    :type,
    :config,
    :selected_by,
    :updated_at,
    svg_path: "",
    height: 0,
    width: 0,
    labels: [],
    drag: false,
    position: %{x: 0, y: 0},
    connectors: %{},
    connected_items: %{},
    raw_size: %{height: 0, width: 0}
  ]

  @type position() :: %{
          x: number(),
          y: number()
        }

  @type selected_by() :: pid() | nil
  @type connection_type() :: :hover | :connected

  @type remote_key :: {item_id :: String.t(), ItemProperties.connector_key()}

  @type t() :: %__MODULE__{
          id: String.t(),
          config: ItemConfig.t(),
          position: position(),
          height: number(),
          width: number(),
          svg_path: String.t(),
          type: String.t(),
          labels: [ItemProperties.label()],
          selected_by: selected_by(),
          drag: boolean(),
          connectors: ItemProperties.connectors(),
          updated_at: DateTime.t(),
          connected_items: ItemProperties.connected_items(),
          raw_size: ItemProperties.size()
        }

  @spec create(type :: String.t(), position :: position()) :: t()
  def create(type, position) when is_binary(type) do
    config = Map.fetch!(available_types(), type)

    %__MODULE__{
      id: Ecto.UUID.autogenerate(),
      position: normalize_position(position),
      type: type,
      config: config,
      updated_at: DateTime.now!("Etc/UTC")
    }
    |> refresh_item()
  end

  @spec update_position(t(), position()) :: t()
  def update_position(%__MODULE__{} = item, position) do
    %__MODULE__{
      item
      | position: normalize_position(position)
    }
  end

  @spec put_updated_at(t(), DateTime.t()) :: t()
  def put_updated_at(%__MODULE__{} = item, %DateTime{} = timestamp) do
    %__MODULE__{item | updated_at: timestamp}
  end

  @spec put_connection(
          t(),
          own_key :: ItemProperties.connector_key(),
          ItemProperties.connection()
        ) :: t()
  def put_connection(%__MODULE__{} = item, own_key, connection) do
    item.connected_items
    |> update_in(&Map.put(&1, own_key, connection))
    |> refresh_item()
  end

  @spec delete_connection(t(), own_key :: ItemProperties.connector_key()) :: t()
  def delete_connection(%__MODULE__{} = item, own_key) do
    item.connected_items
    |> update_in(&Map.delete(&1, own_key))
    |> refresh_item()
  end

  defp normalize_position(%{x: x, y: y}) do
    %{x: max(x, 0), y: max(y, 0)}
  end

  def available_types do
    %{
      "simple_action" => %ItemConfig{
        label: "action",
        parent: :action,
        has_next_action?: true,
        child_actions: [],
        child_connections: []
      },
      "value" => %ItemConfig{
        label: "value",
        parent: :connection,
        has_next_action?: false,
        child_actions: [],
        child_connections: []
      },
      "if" => %ItemConfig{
        label: "if",
        parent: :action,
        has_next_action?: true,
        child_actions: ["then", "else"],
        child_connections: ["condition"]
      }
    }
  end

  @spec set_selected_by(t(), selected_by()) :: t()
  def set_selected_by(%__MODULE__{} = item, selected_by) do
    %__MODULE__{item | selected_by: selected_by}
  end

  @spec set_drag(t(), boolean()) :: t()
  def set_drag(%__MODULE__{} = item, drag) do
    %__MODULE__{item | drag: drag}
  end

  @spec get_parent_key(t()) :: ItemProperties.connector_key() | nil
  def get_parent_key(%__MODULE__{} = item) do
    Enum.find(
      @parent_keys,
      &Map.has_key?(item.connectors, &1)
    )
  end

  @spec get_child_keys(t()) :: [ItemProperties.connector_key()]
  def get_child_keys(%__MODULE__{connectors: connectors}) do
    connectors
    |> Map.keys()
    |> Enum.reject(&(&1 in @parent_keys))
  end

  @spec list_children_ids(t()) :: [String.t()]
  def list_children_ids(%__MODULE__{} = item) do
    item.connected_items
    |> Enum.reject(fn {key, %{type: type}} ->
      not_connected = type != :connected
      parent = key in @parent_keys
      parent || not_connected
    end)
    |> Enum.map(fn {_, %{remote_key: {id, _}}} -> id end)
  end

  @spec remote_key(t(), ItemProperties.connector_key()) :: remote_key()
  def remote_key(%__MODULE__{id: id}, key), do: {id, key}

  @spec refresh_item(t()) :: t()
  defp refresh_item(%__MODULE__{} = item) do
    svg_components = ItemConfig.compute_svg_components(item.config, item.connected_items)

    %ItemProperties{} =
      properties = ItemConfig.compute_item_properties(svg_components, item.config)

    %__MODULE__{
      item
      | svg_path: ItemConfig.svg_components_to_path(svg_components),
        width: properties.width,
        height: properties.height,
        connectors: properties.connectors,
        raw_size: properties.raw_size,
        labels: properties.labels
    }
  end

  @spec get_min_item_size(t()) :: ItemProperties.size()
  def get_min_item_size(%__MODULE__{config: %{parent: parent}}) do
    ItemConfig.min_child_item_size()
    |> Map.get(parent, %{height: 0, width: 0})
  end
end
