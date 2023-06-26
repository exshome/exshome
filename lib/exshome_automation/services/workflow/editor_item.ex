defmodule ExshomeAutomation.Services.Workflow.EditorItem do
  @moduledoc """
  Editor item.
  """

  alias ExshomeAutomation.Services.Workflow.ItemConfig
  alias ExshomeAutomation.Services.Workflow.ItemProperties

  defstruct [
    :id,
    :type,
    :config,
    :height,
    :width,
    :svg_path,
    :connectors,
    :selected_by,
    :updated_at,
    :drag,
    position: %{x: 0, y: 0},
    connections: %{}
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
          selected_by: selected_by(),
          drag: boolean(),
          connectors: ItemProperties.connector_mapping(),
          updated_at: DateTime.t(),
          connections: %{
            ItemProperties.connector_key() => %{
              remote_key: remote_key(),
              type: connection_type()
            }
          }
        }

  @spec create(type :: String.t(), position :: position()) :: t()
  def create(type, position) when is_binary(type) do
    default_values = available_types()[type]

    %__MODULE__{
      default_values
      | id: Ecto.UUID.autogenerate(),
        position: normalize_position(position),
        type: type
    }
    |> refresh_item()
  end

  @spec update_position(t(), position()) :: t()
  def update_position(%__MODULE__{} = item, position) do
    %__MODULE__{
      item
      | position: normalize_position(position)
    }
    |> refresh_item()
  end

  @spec put_updated_at(t(), DateTime.t()) :: t()
  def put_updated_at(%__MODULE__{} = item, %DateTime{} = timestamp) do
    %__MODULE__{item | updated_at: timestamp}
  end

  @spec put_connection(
          t(),
          own_key :: ItemProperties.connector_key(),
          remote_key :: remote_key(),
          type :: connection_type()
        ) :: t()
  def put_connection(%__MODULE__{} = item, own_key, remote_key, type) do
    update_in(
      item.connections,
      &Map.put(&1, own_key, %{type: type, remote_key: remote_key})
    )
  end

  @spec delete_connection(t(), own_key :: ItemProperties.connector_key()) :: t()
  def delete_connection(%__MODULE__{} = item, own_key) do
    update_in(item.connections, &Map.delete(&1, own_key))
  end

  defp normalize_position(%{x: x, y: y}) do
    %{x: max(x, 0), y: max(y, 0)}
  end

  def available_types do
    %{
      "simple_action" => %__MODULE__{
        height: 46,
        width: 34,
        position: %{x: 0, y: 0},
        config: %ItemConfig{
          parent: :action,
          has_next_action?: true,
          child_actions: [],
          child_connections: []
        }
      },
      "value" => %__MODULE__{
        height: 46,
        width: 34,
        position: %{x: 0, y: 0},
        config: %ItemConfig{
          parent: :connection,
          has_next_action?: false,
          child_actions: [],
          child_connections: []
        }
      },
      "if" => %__MODULE__{
        height: 46,
        width: 34,
        position: %{x: 0, y: 0},
        config: %ItemConfig{
          parent: :action,
          has_next_action?: true,
          child_actions: [
            %{height: 3, id: "if clause"},
            %{height: 3, id: "then clause"}
          ],
          child_connections: [
            %{height: 3, id: "condition"}
          ]
        }
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

  @spec refresh_item(t()) :: t()
  defp refresh_item(%__MODULE__{} = item) do
    svg_components = ItemConfig.compute_svg_components(item.config)
    %ItemProperties{} = properties = ItemConfig.compute_item_properties(svg_components)

    %__MODULE__{
      item
      | svg_path: ItemConfig.svg_components_to_path(svg_components),
        width: properties.width,
        height: properties.height,
        connectors: properties.connectors
    }
  end
end
