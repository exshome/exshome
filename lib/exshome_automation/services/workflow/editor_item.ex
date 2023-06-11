defmodule ExshomeAutomation.Services.Workflow.EditorItem do
  @moduledoc """
  Editor item.
  """

  alias ExshomeAutomation.Services.Workflow.ItemConfig
  alias ExshomeAutomation.Services.Workflow.ItemConfig.Properties

  defstruct [
    :id,
    :type,
    :config,
    :height,
    :width,
    :svg_path,
    :connectors,
    :selected_by,
    :drag,
    position: %{x: 0, y: 0}
  ]

  @type position() :: %{
          x: number(),
          y: number()
        }

  @type selected_by() :: pid() | nil

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
          connectors: Properties.connector_mapping()
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

  defp normalize_position(%{x: x, y: y}) do
    %{x: max(x, 0), y: max(y, 0)}
  end

  def available_types do
    %{
      "rect" => %__MODULE__{
        height: 46,
        width: 34,
        position: %{x: 0, y: 0},
        config: %ItemConfig{
          has_previous_action?: true,
          has_next_action?: true,
          has_parent_connection?: true,
          child_actions: [
            %{height: 3, id: "first_action"},
            %{height: 3, id: "second_action"}
          ],
          child_connections: [
            %{height: 3, id: "first_connection"},
            %{height: 3, id: "second_connection"}
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
    %Properties{} = properties = ItemConfig.compute_item_properties(svg_components)

    %__MODULE__{
      item
      | svg_path: ItemConfig.svg_components_to_path(svg_components),
        width: properties.width,
        height: properties.height,
        connectors: properties.connectors
    }
  end
end
