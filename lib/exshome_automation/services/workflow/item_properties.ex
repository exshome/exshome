defmodule ExshomeAutomation.Services.Workflow.ItemProperties do
  @moduledoc """
  Struct for storing item property settings
  """

  defstruct [
    :height,
    :width,
    connectors: %{}
  ]

  @type child_connector_type() :: :action | :connector
  @type connector_key() ::
          :parent_connector | :parent_action | {child_connector_type(), id :: String.t()}
  @type connector_type() :: :parent | child_connector_type()
  @type connector_position() :: %{
          x: number(),
          y: number(),
          height: number(),
          width: number()
        }
  @type connectors() :: %{connector_key() => connector_position()}

  @type t() :: %__MODULE__{
          height: number(),
          width: number(),
          connectors: connectors()
        }

  @type remote_key :: {item_id :: String.t(), connector_key()}
  @type connection_type() :: :hover | :connected
  @type connection() :: %{
          remote_key: remote_key(),
          type: connection_type(),
          height: number(),
          width: number()
        }
  @type connected_items() :: %{connector_key() => connection()}

  @spec connector_type(connector_key()) :: connector_type()
  def connector_type(:parent_connector), do: :parent
  def connector_type(:parent_action), do: :parent
  def connector_type({:action, _}), do: :action
  def connector_type({:connector, _}), do: :connector

  @spec parent_type(connector_key()) :: connector_type()
  def parent_type(:parent_connector), do: :connector
  def parent_type(:parent_action), do: :action

  @spec position_intersects?(connector_position(), connector_position()) :: boolean()
  def position_intersects?(p1, p2) do
    intersects_x_1 = p1.x <= p2.x && p1.x + p1.width >= p2.x
    intersects_x_2 = p2.x <= p1.x && p2.x + p2.width >= p1.x
    intersects_x = intersects_x_1 || intersects_x_2

    intersects_y_1 = p1.y <= p2.y && p1.y + p1.height >= p2.y
    intersects_y_2 = p2.y <= p1.y && p2.y + p2.height >= p1.y
    intersects_y = intersects_y_1 || intersects_y_2

    intersects_x && intersects_y
  end

  @spec child_connector_key(child_connector_type(), String.t()) :: connector_key()
  def child_connector_key(type, id), do: {type, id}
end
